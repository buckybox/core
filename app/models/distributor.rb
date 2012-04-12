class Distributor < ActiveRecord::Base
  has_one :bank_information,    dependent: :destroy
  has_one :invoice_information, dependent: :destroy

  has_many :boxes,              dependent: :destroy
  has_many :routes,             dependent: :destroy
  has_many :orders,             dependent: :destroy, through: :boxes
  has_many :deliveries,         dependent: :destroy, through: :orders
  has_many :payments,           dependent: :destroy
  has_many :customers,          autosave: true # Want to save those customers added via import_customers
  has_many :accounts,           dependent: :destroy, through: :customers
  has_many :invoices,           dependent: :destroy, through: :accounts
  has_many :transactions,       dependent: :destroy, through: :accounts
  has_many :events
  has_many :delivery_lists,     dependent: :destroy
  has_many :packing_lists,      dependent: :destroy
  has_many :packages,           dependent: :destroy, through: :packing_lists

  DEFAULT_ADVANCED_HOURS = 18
  DEFAULT_ADVANCED_DAYS = 3
  DEFAULT_AUTOMATIC_DELIVERY_HOUR = 18
  DEFAULT_AUTOMATIC_DELIVERY_DAYS = 1

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :company_logo, CompanyLogoUploader

  composed_of :invoice_threshold,
    class_name: "Money",
    mapping: [%w(invoice_threshold_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url, :company_logo, :company_logo_cache, :completed_wizard,
    :remove_company_logo, :support_email, :invoice_threshold, :separate_bucky_fee, :advance_hour, :advance_days, :automatic_delivery_hour, :time_zone

  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :name, on: :update
  validates_uniqueness_of :name, on: :update
  validates_numericality_of :advance_hour, greater_than_or_equal_to: 0
  validates_numericality_of :advance_days, greater_than_or_equal_to: 1
  validates_numericality_of :automatic_delivery_hour, greater_than_or_equal_to: 0

  before_validation :parameterize_name
  before_validation :check_emails
  before_validation :generate_default_automate_values

  after_save :generate_required_daily_lists

  default_scope order('created_at DESC')

  # Devise Override: Avoid validations on update or if now password provided
  def password_required?
    password.present? && password.size > 0 || new_record?
  end

  def self.create_daily_lists(time = Time.current)
    all.each do |distributor|
      distributor.use_local_time_zone do
        local_time = time.in_time_zone

        if local_time.hour == distributor.advance_hour
          successful = distributor.generate_required_daily_lists

          details = ["#{distributor.name}",
                     "TZ #{distributor.time_zone} #{Time.current}"].join("\n")
          if successful
            CronLog.log("Create daily list for #{distributor.id} at local time #{local_time.to_s(:pretty)} successful.", details)
          else
            CronLog.log("FAILURE: Create daily list for #{distributor.id} at local time #{local_time.to_s(:pretty)}.", details)
          end
        end
      end
    end
  end

  def self.automate_completed_status(time = Time.current)
    all.each do |distributor|
      distributor.use_local_time_zone do
        local_time = time.in_time_zone

        if local_time.hour == distributor.automatic_delivery_hour
          # considering the next day as standard across all distributors for now
          successful = distributor.automate_completed_status

          if successful
            CronLog.log("Automated completion for #{distributor.id} at local time #{local_time.to_s(:pretty)} successful.")
          else
            CronLog.log("FAILURE: Automated completion for #{distributor.id} at local time #{local_time.to_s(:pretty)}.")
          end
        end
      end
    end
  end

  def generate_required_daily_lists
    days_to_generate = (advance_days - 1) # this is because we are including the start date

    # If we have missed the cutoff point add a day so we start generation from tomorrow
    if_closed  = ( advance_hour < Time.current.hour ? 1 : 0 )
    start_date = Date.current + if_closed.day
    end_date   = Date.current + if_closed.day + days_to_generate.days

    newest_list_date = packing_lists.last.date if packing_lists.last

    successful = true # assume all is good with the world

    if newest_list_date && (newest_list_date > end_date)
      # Only need to delete the difference
      start_date = end_date + 1.day
      end_date = newest_list_date

      (start_date..end_date).each do |date|
        # Seek and destroy (http://youtu.be/wLBpLz5ELPI?t=3m10s) the lists that are now out of range
        packing_list  = packing_lists.find_by_date(date)
        successful &= packing_list.destroy  unless packing_list.nil?

        delivery_list = delivery_lists.find_by_date(date)
        successful &= delivery_list.destroy unless delivery_list.nil?
      end
    else
      # Only generate the lists that don't exist yet
      start_date = newest_list_date unless newest_list_date.nil?

      unless start_date == end_date # the packing list already exists so don't boher generating
        (start_date..end_date).each do |date|
          packing_list = PackingList.generate_list(self, date)
          delivery_list = DeliveryList.generate_list(self, date)

          successful &= packing_list.date == date && delivery_list.date == date
        end
      end
    end

    return successful
  end

  # Date is always in distributors timezone
  def automate_completed_status
    # If we have missed the cutoff point add a day so we start auto deliveries from today
    if_passed  = ( automatic_delivery_hour < Time.current.hour ? 1 : 0 )

    date = Date.yesterday + if_passed.day

    dates_delivery_lists = delivery_lists.find_by_date(date)
    dates_packing_lists  = packing_lists.find_by_date(date)

    successful = true

    successful &= dates_packing_lists.mark_all_as_auto_packed     if dates_packing_lists
    successful &= dates_delivery_lists.mark_all_as_auto_delivered if dates_delivery_lists

    return successful
  end

  def local_time_zone
    [time_zone, BuckyBox::Application.config.time_zone].select(&:present?).first
  end

  def change_to_local_time_zone
    new_time_zone = local_time_zone
    Time.zone = new_time_zone unless new_time_zone.blank?
  end

  def use_local_time_zone
    new_time_zone = local_time_zone
    Time.use_zone(new_time_zone) do
      yield
    end
  end

  def import_customers(loaded_customers)
    Distributor.transaction do
      use_local_time_zone do
        raise "No customers" if loaded_customers.blank?

        expected = Bucky::Import::Customer
        raise "Expecting #{expected} but was #{loaded_customers.first.class}" unless loaded_customers.first.class == expected

        loaded_customers.each do |c|
          customer = customers.find_by_number(c.number) || self.customers.build({number: c.number})

          c_route = routes.find_by_name(c.delivery_route)
          raise "Route #{c.delivery_route} not found for distributor with id #{id}" if c_route.blank?
          customer.import(c, c_route)
        end
      end
    end
  end

  private

  def generate_default_automate_values
    self.advance_hour            = DEFAULT_AUTOMATIC_DELIVERY_HOUR if self.advance_hour.nil?
    self.advance_days            = DEFAULT_ADVANCED_DAYS           if self.advance_days.nil?
    self.automatic_delivery_hour = DEFAULT_AUTOMATIC_DELIVERY_HOUR if self.automatic_delivery_hour.nil?
  end

  def parameterize_name
    self.parameter_name = name.parameterize if self.name
  end

  def check_emails
    if self.email
      self.email.strip!
      self.email.downcase!
    end

    self.support_email = self.email if self.support_email.blank?
  end
end
