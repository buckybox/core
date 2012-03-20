class Distributor < ActiveRecord::Base
  has_one :bank_information,    dependent: :destroy
  has_one :invoice_information, dependent: :destroy

  has_many :boxes,              dependent: :destroy
  has_many :routes,             dependent: :destroy
  has_many :orders,             dependent: :destroy, through: :boxes
  has_many :deliveries,         dependent: :destroy, through: :orders
  has_many :payments,           dependent: :destroy
  has_many :customers
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

  before_save :update_daily_lists, if: 'advance_days_changed? && !advance_days_was.nil?'

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
          advance_time = (local_time + distributor.advance_days.days)
          successful = distributor.create_daily_lists(advance_time.to_date)

          details = ["#{distributor.name}",
                     "TZ #{distributor.time_zone} #{Time.current}"].join("\n")
          if successful
            CronLog.log("Create daily list for #{distributor.id} at #{advance_time.to_s(:pretty)} successful.", details)
          else
            CronLog.log("FAILURE: Create daily list for #{distributor.id} at #{advance_time.to_s(:pretty)}.", details)
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
          delivery_time = (local_time - 1.day) # considering the next day as standard across all distributors for now
          successful = distributor.automate_completed_status(delivery_time.to_date)

          if successful
            CronLog.log("Automated completion for #{distributor.id} at #{delivery_time.to_s(:pretty)} successful.")
          else
            CronLog.log("FAILURE: Automated completion for #{distributor.id} at #{delivery_time.to_s(:pretty)}.")
          end
        end
      end
    end
  end

  def create_daily_lists(date = Date.current)
    packing_list = PackingList.generate_list(self, date)
    delivery_list = DeliveryList.generate_list(self, date)

    return packing_list.date == date && delivery_list.date == date
  end

  # date is always in distributors timezone
  def automate_completed_status(date = nil)
    use_local_time_zone do
      date ||= Date.yesterday #Will return the correct date for this distributor
      dates_delivery_lists = delivery_lists.find_by_date(date)
      dates_packing_lists  = packing_lists.find_by_date(date)

      # If the list were not created on this date for some reason create them first
      unless !!dates_delivery_lists || !!dates_packing_lists
        create_daily_lists(date)
        dates_delivery_lists = delivery_lists.find_by_date(date)
        dates_packing_lists  = packing_lists.find_by_date(date)
      end

      successful  = dates_delivery_lists.mark_all_as_auto_delivered
      successful &= dates_packing_lists.mark_all_as_auto_packed

      return successful
    end
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

  private

  def update_daily_lists
    old_days, new_days = self.advance_days_change
    old_date = Date.current + old_days.days
    new_date = Date.current + new_days.days

    if old_days < new_days
      ((old_date + 1.day)..new_date).each { |date| create_daily_lists(date) }
    else
      ((new_date + 1.day)..old_date).each do |date|
        packing_list = PackingList.find_by_distributor_id_and_date(id, date)
        packing_list.destroy unless packing_list.nil?

        delivery_list = DeliveryList.find_by_distributor_id_and_date(id, date)
        delivery_list.destroy unless delivery_list.nil?
      end
    end
  end

  def generate_default_automate_values
    self.advance_hour = DEFAULT_AUTOMATIC_DELIVERY_HOUR            if self.advance_hour.nil?
    self.advance_days = DEFAULT_ADVANCED_DAYS             if self.advance_days.nil?
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
