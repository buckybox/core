class Distributor < ActiveRecord::Base
  include IceCube

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

  serialize :daily_lists_schedule,   Hash
  serialize :auto_delivery_schedule, Hash

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
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url,
    :company_logo, :company_logo_cache, :completed_wizard, :remove_company_logo, :support_email,
    :invoice_threshold_cents, :separate_bucky_fee, :time_zone

  validates_presence_of :email
  validates_uniqueness_of :email

  validates_presence_of :name, on: :update
  validates_uniqueness_of :name, on: :update

  before_validation :parameterize_name
  before_validation :check_emails
  before_validation :generate_daily_lists_schedule, if: 'daily_lists_schedule.to_s.blank?'
  before_validation :generate_auto_delivery_schedule, if: 'auto_delivery_schedule.to_s.blank?'

  # Devise Override: Avoid validations on update or if now password provided
  def password_required?
    password.present? && password.size > 0 || new_record?
  end

  def self.create_daily_lists(time = nil)
    self.change_to_local_timezone
    time ||= Time.current

    logger.info "--- Checking distributor for daily list generation (#{time}) ---"

    all.each do |distributor|
      logger.info "Processing: #{distributor.id} - #{distributor.name} - #{distributor.daily_lists_schedule.start_time}"

      if distributor.daily_lists_schedule.occurring_at?(time)
        logger.info '> Creating daily list...'

        successful = distributor.create_daily_lists(time.to_date)

        if successful
          logger.info '> Found or created successfully.'
        else
          logger.error '> Was not able to create a the daily lists.'
        end
      end
    end
  end

  def self.automate_completed_status(time = nil)
    self.change_to_local_timezone
    time ||= Time.current

    logger.info "--- Marking distributor daily lists as complete (#{time}) ---"

    all.each do |distributor|
      logger.info "Processing: #{distributor.id} - #{distributor.name} - #{distributor.auto_delivery_schedule.start_time}"

      if distributor.auto_delivery_schedule.occurring_at?(time)
        logger.info 'Marking lists as completed...'
        successful = distributor.automate_completed_status(time.to_date)

        if successful
          logger.info "> All items have been marked as completed for this date."
        else
          logger.error "> Was not able to mark items as complete for this date."
        end
      end
    end
  end

  def daily_lists_schedule
    Schedule.from_hash(self[:daily_lists_schedule]) if self[:daily_lists_schedule]
  end

  def daily_lists_schedule=(daily_lists_schedule)
    raise(ArgumentError, 'The daily list schedule can not be updated this way. Please use the schedule generation method.')
  end

  def auto_delivery_schedule
    Schedule.from_hash(self[:auto_delivery_schedule]) if self[:auto_delivery_schedule]
  end

  def auto_delivery_schedule=(auto_delivery_schedule)
    raise(ArgumentError, 'The auto delivery schedule can not be updated this way. Please use the schedule generation method.')
  end

  def generate_daily_lists_schedule(time = Time.current.beginning_of_day)
    time = time.change(min: 0, sec: 0, usec: 0) # make sure time starts on the hour
    schedule = Schedule.new(time, duration: 3600) # make sure it lasts for an hour
    schedule.add_recurrence_rule Rule.daily # and have it reoccur daily
    self[:daily_lists_schedule] = schedule.to_hash
  end

  def generate_auto_delivery_schedule(time = Time.current.end_of_day)
    time = time.change(min: 0, sec: 0, usec: 0) # make sure time starts on the hour
    schedule = Schedule.new(time, duration: 3600) # make sure it lasts for an hour
    schedule.add_recurrence_rule Rule.daily # and have it reoccur daily
    self[:auto_delivery_schedule] = schedule.to_hash
  end

  def create_daily_lists(date = Date.current)
    packing_list = PackingList.generate_list(self, date)
    delivery_list = DeliveryList.generate_list(self, date)

    return packing_list.persisted? && delivery_list.persisted?
  end

  def automate_completed_status(date = Date.yesterday)
    dates_delivery_lists = delivery_lists.find_by_date(date)
    dates_packing_lists  = packing_lists.find_by_date(date)

    # If the list were not created on this date for some reason create them first
    create_daily_lists(date) unless !!dates_delivery_lists || !!dates_packing_lists

    successful  = dates_delivery_lists.mark_all_as_auto_delivered
    successful &= dates_packing_lists.mark_all_as_auto_packed

    return successful
  end

  def change_to_local_time_zone
    new_time_zone = [time_zone, BuckyBox::Application.config.time_zone].select(&:present?).first
    Time.zone = new_time_zone unless new_time_zone.blank?
  end

  def use_local_time_zone
    new_time_zone = [time_zone, BuckyBox::Application.config.time_zone].select(&:present?).first
    Time.use_zone(new_time_zone) do
      yield
    end
  end

  private

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
