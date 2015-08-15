require "csv"
require "email_template"

class Distributor < ActiveRecord::Base
  include Bucky::Email

  has_one :bank_information,          dependent: :destroy
  has_one :localised_address,         dependent: :destroy, as: :addressable, autosave: true

  has_many :extras,                   dependent: :destroy
  has_many :boxes,                    dependent: :destroy
  has_many :delivery_services,        dependent: :destroy
  has_many :orders,                   dependent: :destroy, through: :boxes
  has_many :deliveries,               dependent: :destroy, through: :orders
  has_many :payments,                 dependent: :destroy
  has_many :deductions,               dependent: :destroy
  has_many :customers,                dependent: :destroy
  has_many :accounts,                 dependent: :destroy, through: :customers
  has_many :transactions,             dependent: :destroy, through: :accounts
  has_many :events,                   dependent: :destroy
  has_many :delivery_lists,           dependent: :destroy
  has_many :packing_lists,            dependent: :destroy
  has_many :packages,                 dependent: :destroy, through: :packing_lists
  has_many :line_items,               dependent: :destroy
  has_many :import_transaction_lists, dependent: :destroy
  has_many :import_transactions,      dependent: :destroy, through: :import_transaction_lists
  has_many :distributors_omni_importers, class_name: DistributorsOmniImporters
  has_many :omni_importers, through: :distributors_omni_importers

  # Metrics
  has_many :distributor_metrics
  has_many :distributor_logins
  has_many :customer_logins
  has_many :customer_checkouts

  belongs_to :country

  DEFAULT_TIME_ZONE       = 'Wellington'
  DEFAULT_CURRENCY        = 'NZD'
  DEFAULT_ADVANCED_HOURS  = 18
  DEFAULT_ADVANCED_DAYS   = 3
  MAX_ADVANCED_DAYS       = 14
  AUTOMATIC_DELIVERY_HOUR = 23
  HUMANIZED_ATTRIBUTES    = {
    email: "Account login email"
  }

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable,
    :lockable, unlock_strategy: :none # don't let them unlock themselves for now

  acts_as_taggable

  mount_uploader :company_logo, CompanyLogoUploader
  mount_uploader :company_team_image, CompanyTeamImageUploader

  monetize :consumer_delivery_fee_cents
  monetize :default_balance_threshold_cents

  # Actual model attributes
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url,
    :company_logo, :company_logo_cache, :remove_company_logo, :company_team_image,
    :company_team_image_cache, :remove_company_team_image, :completed_wizard, :support_email,
    :separate_bucky_fee, :advance_hour, :advance_days, :time_zone, :currency,
    :country_id, :consumer_delivery_fee, :consumer_delivery_fee_cents, :active_webstore, :about,
    :details, :facebook_url, :city, :parameter_name, :spend_limit_on_all_customers,
    :feature_spend_limit, :contact_name, :tag_list, :omni_importer_ids, :notes, :email_templates,
    :phone, :localised_address_attributes, :api_key, :api_secret, :overdue

  # Intro flags
  attr_accessible :customers_show_intro, :deliveries_index_packing_intro,
    :deliveries_index_deliveries_intro, :payments_index_intro, :customers_index_intro

  # Settings
  attr_accessible :locale, :customer_can_edit_orders, :customer_can_remove_orders,
    :default_balance_threshold, :has_balance_threshold, :send_email, :send_halted_email,
    :collect_phone, :collect_delivery_note, :require_address_1, :require_address_2, :require_suburb,
    :require_postcode, :require_phone, :require_city, :require_delivery_note,
    :payment_cash_on_delivery, :payment_bank_deposit, :payment_paypal, :paypal_email,
    :payment_credit_card, :keep_me_updated, :notify_address_change, :notify_for_new_webstore_order,
    :email_customer_on_new_webstore_order, :email_customer_on_new_order,
    :email_distributor_on_new_webstore_order, :ga_tracking_id

  accepts_nested_attributes_for :localised_address

  validates_presence_of :country, :email, :name, :support_email, :time_zone
  validates_uniqueness_of :email, :name
  validates_uniqueness_of :api_key, allow_nil: true
  validates_uniqueness_of :parameter_name, allow_nil: true
  validates_numericality_of :advance_hour, greater_than_or_equal_to: 0
  validates_numericality_of :advance_days, greater_than_or_equal_to: 0
  validate :required_fields_for_webstore
  validate :validate_parameter_name
  validate :validate_require_phone
  validate :validate_require_delivery_note

  before_validation :check_emails
  before_create :parameterize_name, if: 'parameter_name.nil?'
  after_create :send_welcome_email

  after_create :tracking_after_create

  after_save :generate_required_daily_lists # TODO: should trigger only when YZ is changed, not all the fucking time!!!
  after_save :update_halted_statuses
  after_save :tracking_after_save

  serialize :email_templates, Array

  default_value_for :time_zone,             DEFAULT_TIME_ZONE
  default_value_for :currency,              DEFAULT_CURRENCY
  default_value_for :advance_hour,          DEFAULT_ADVANCED_HOURS
  default_value_for :advance_days,          DEFAULT_ADVANCED_DAYS
  default_value_for :notify_address_change, true

  scope :keep_updated,    -> { where(keep_me_updated: true) }
  scope :active_webstore, -> { where(active_webstore: true) }

  delegate :tracking_after_create, :tracking_after_save, :track, to: :messaging

  attr_reader :spend_limit_on_all_customers
  alias_method :spend_limit_on_all_customers?, :spend_limit_on_all_customers

  # Devise Override: Avoid validations on update or if now password provided
  def password_required?
    password.present? && password.size > 0 || new_record?
  end

  def self.active
    where("last_seen_at > ?", 30.days.ago)
      .select { |d| d.transactional_customer_count > 9 }
      .sort_by(&:transactional_customer_count).reverse
  end

  def self.refresh_webstore_caches
    return unless Rails.env.production?

    duration = Benchmark.realtime do
      active_webstore.active.each_slice(5) do |distributors|
        hydra = Typhoeus::Hydra.hydra

        distributors.each do |distributor|
          # TODO: don't hardcode URL once we migrate the web store to other app
          url = "https://store.buckybox.com/#{distributor.parameter_name}"

          request = Typhoeus::Request.new(url, timeout: 45)
          request.on_complete do |response|
            unless response.success?
              error = "Could not refresh #{response.request.url}: #{response.return_message}"
              Bugsnag.notify(RuntimeError.new(error))
            end
          end
          hydra.queue request
        end

        hydra.run # this is a blocking call that returns once all requests are complete
        sleep 5
      end
    end.round

    if duration > 4.minutes
      Bugsnag.notify(RuntimeError.new("Refreshing caches took too long (#{duration}s)"))
    end

    CronLog.log("Refreshed web store caches in #{duration}s.")
  end

  def self.create_daily_lists(time = Time.current)
    find_each do |distributor|
      distributor.use_local_time_zone do
        local_time = time.in_time_zone

        if local_time.hour == distributor.advance_hour
          successful = distributor.generate_required_daily_lists

          details = ["#{distributor.name}", "TZ #{distributor.time_zone} #{Time.current}"].join("\n")

          if successful
            CronLog.log("Create daily list for #{distributor.id} at local time #{local_time.to_s(:pretty)} successful.", details)
          else
            message = "FAILURE: Create daily list for #{distributor.id} at local time #{local_time.to_s(:pretty)}."

            CronLog.log(message, details)
            Bugsnag.notify(RuntimeError.new("#{message} #{details}"))
          end
        end
      end
    end
  end

  def self.automate_completed_status(time = Time.current)
    find_each do |distributor|
      distributor.use_local_time_zone do
        local_time = time.in_time_zone

        if local_time.hour == AUTOMATIC_DELIVERY_HOUR
          successful = distributor.automate_completed_status

          details = ["#{distributor.name}", "TZ #{distributor.time_zone} #{Time.current}"].join("\n")

          if successful
            CronLog.log("Automated completion for #{distributor.id} at local time #{local_time.to_s(:pretty)} successful.", details)
          else
            message = "FAILURE: Automated completion for #{distributor.id} at local time #{local_time.to_s(:pretty)}."

            CronLog.log(message, details)
            Bugsnag.notify(RuntimeError.new("#{message} #{details}"))
          end
        end
      end
    end
  end

  def self.update_next_occurrence_caches
    find_each do |distributor|
      distributor.use_local_time_zone do
        if Time.current.hour == AUTOMATIC_DELIVERY_HOUR
          CronLog.log("Updated next order caches for #{distributor.id} at local time #{Time.current.to_s(:pretty)}.")
          distributor.update_next_occurrence_caches
        end
      end
    end
  end

  def self.mark_as_seen!(distributor, options = {})
    return if distributor.nil? || options[:no_track]
    distributor.mark_as_seen!
  end

  def webstore_url
    "https://store.buckybox.com/#{parameter_name}".freeze
  end

  def mark_as_seen!
    touch(:last_seen_at) # No validations or callbacks are performed
  end

  def email_from(email: support_email)
    sanitize_email_header "#{name} <#{email}>"
  end

  def email_to
    sanitize_email_header "#{contact_name} <#{email}>"
  end

  def banks
    omnis = omni_importers.bank_deposit | omni_importers.paypal
    omnis.map(&:bank_name).uniq
  end

  def separate_bucky_fee?
    ActiveSupport::Deprecation.warn("Distributor#separate_bucky_fee? is deprecated", caller(2))

    self[:separate_bucky_fee]
  end

  def consumer_delivery_fee_cents
    0 # NOTE: legacy, kept for future use
  end

  def update_next_occurrence_caches(date = nil)
    use_local_time_zone do
      if Time.current.hour >= AUTOMATIC_DELIVERY_HOUR
        date ||= Date.current.tomorrow
      else
        date ||= Date.current
      end
      Bucky::Sql.update_next_occurrence_caches(self, date)
    end
  end

  def window_start_from
    use_local_time_zone do
      # If we have missed the cutoff point add a day so we start generation from tomorrow
      Date.current + (advance_hour <= Time.current.hour ? 1 : 0).days
    end
  end

  def beginning_of_green_zone
    window_end_at + 1.day
  end

  def window_end_at
    days_to_generate = (advance_days - 1) # this is because we are including the start date
    window_start_from + days_to_generate.days
  end

  def generate_required_daily_lists(generator_class = GenerateRequiredDailyLists)
    generate_required_daily_lists_between(window_start_from, window_end_at, generator_class)
  end

  def generate_required_daily_lists_between(start, finish, generator_class = GenerateRequiredDailyLists)
    generator = generator_class.new(
      distributor:        self,
      window_start_from:  start,
      window_end_at:      finish,
      packing_lists:      packing_lists.scoped,
      delivery_lists:     delivery_lists.scoped,
    )
    generator.generate
  end

  # Date is always in distributors timezone
  def automate_completed_status
    now = Time.current
    date = now.to_date - 1.day

    # If we have missed the cutoff point add a day so we start auto deliveries from today
    date += 1.day if now.hour >= Distributor::AUTOMATIC_DELIVERY_HOUR

    dates_delivery_lists = delivery_lists.find_by_date(date)
    dates_packing_lists  = packing_lists.find_by_date(date)

    successful = true

    successful &= dates_packing_lists.mark_all_as_auto_packed     if dates_packing_lists
    successful &= dates_delivery_lists.mark_all_as_auto_delivered if dates_delivery_lists

    successful
  end

  def local_time_zone
    time_zone
  end

  def use_local_time_zone
    Time.use_zone(time_zone) do
      yield
    end
  end

  def find_duplicate_import_transactions(date, description, amount)
    import_transactions.processed.not_duplicate.not_removed.where(transaction_date: date, description: description, amount_cents: amount.cents)
  end

  def find_previous_match(description)
    import_transactions.processed.matched.not_removed.where(description: description).ordered.last
  end

  def last_used_omni_importer(prefered = nil)
    prefered ||
      import_transaction_lists.order('created_at DESC').first.try(:omni_importer) ||
      omni_importers.ordered.first
  end

  def omni_importers?
    omni_importers.any?
  end

  def can_upload_payments?
    omni_importers? && import_transaction_lists.draft.empty?
  end

  def self.parameterize_name(value)
    value.to_s.parameterize
  end

  def parameterize_name(value = nil)
    value = self.name if value.nil? && self.name
    self.parameter_name = Distributor.parameterize_name(value)
  end

  def update_halted_statuses
    if has_balance_threshold_changed? || default_balance_threshold_cents_changed? || spend_limit_on_all_customers?
      Customer.transaction do
        customers.find_each do |customer|
          if spend_limit_on_all_customers?
            customer.update_halted_status!(default_balance_threshold_cents, Customer::EmailRule.only_pending_orders)
          else
            customer.update_halted_status!(nil, Customer::EmailRule.only_pending_orders)
          end
        end
      end
    end
  end

  def spend_limit_on_all_customers=(val)
    @spend_limit_on_all_customers = val.to_bool
  end

  def send_email?
    send_email
  end

  def send_halted_email?
    send_email? && send_halted_email
  end

  def number_of_customers_emailed_after_update(spend_limit, update_existing)
    if update_existing
      customers.joins(:account).where(["accounts.balance_cents <= ? and customers.status_halted = 'f'", spend_limit]).count(&:orders_pending_package_creation?)
    else
      customers.joins(:account).where("accounts.balance_cents <= customers.balance_threshold_cents and customers.status_halted = 'f'").count(&:orders_pending_package_creation?)
    end
  end

  def number_of_customers_halted_after_update(spend_limit, update_existing)
    if update_existing
      customers.joins(:account).where(["accounts.balance_cents <= ? and customers.status_halted = 'f'", spend_limit]).count
    else
      customers.joins(:account).where("accounts.balance_cents <= customers.balance_threshold_cents and customers.status_halted = 'f'").count
    end
  end

  def contact_name_for_email
    contact_name.present? ? contact_name : email
  end

  def location
    [country.full_name, city].reject(&:blank?).join(', ')
  end

  def packing_list_by_date(date)
    PackingList.collect_list(self, date)
  end

  def delivery_list_by_date(date)
    list = delivery_lists.find_by(date: date)
    list = DeliveryList.collect_list(self, date) if list.nil?
    list
  end

  def self.all_payment_options
    {
      cash_on_delivery: I18n.t('cash_on_delivery'),
      bank_deposit: I18n.t('bank_deposit'),
      paypal: I18n.t('paypal_cc'),
    }
  end

  def payment_options
    self.class.all_payment_options.map do |key, label|
      [label, key] if public_send("payment_#{key}")
    end.compact
  end

  def payment_options_string
    payment_options.map(&:first).join(', ')
  end

  def payment_options_symbols
    payment_options.map(&:last)
  end

  def only_one_payment_option?
    payment_options.size == 1
  end

  def only_payment_option
    payment_options.first.last
  end

  def total_customer_count
    customers.count
  end

  def transactional_customer_count
    Bucky::Sql.transactional_customer_count(self)
  end

  def new_transactional_customer_count
    Bucky::Sql.transactional_customer_count(self, 1.week.ago.to_date)
  end

  def new_customer_count
    customers.where("created_at > ?", 1.week.ago).count
  end

  def deliveries_last_7_days_count
    deliveries.delivered.where("deliveries.updated_at > ?", 7.days.ago).count
  end

  def notify_address_changed(customer, notifier = Event)
    return false unless notify_address_change?
    notifier.customer_address_changed(customer)
  end

  def notify_for_new_webstore_customer
    true
  end

  def customers_for_export(customer_ids)
    customers.includes(
      delivery_service: {},
      account: { delivery_service: {} },
      next_order: { box: {} }
    ).ordered.where(id: customer_ids)
  end

  def customer_badges
    @customer_badges ||= customers.map { |customer| [customer.badge, customer.id] }
  end

  def transactions_for_export(from, to)
    from = from.to_time_in_current_zone
    to = to.to_time_in_current_zone
    transactions.includes(account: { customer: { address: {} } })  \
      .where("display_time >= ?", from)                            \
      .where("display_time < ?", to)                               \
      .order('display_time DESC')                                  \
      .order('created_at DESC')
  end

  def skip_tracking?(env = Rails.env)
    messaging.skip?(env)
  end

  def webstore_status_changed?
    active_webstore_changed?
  end

  def generate_api_key!
    return if api_key.present?
    update_attributes(api_key: SecureRandom.uuid, api_secret: SecureRandom.uuid)
  end

  def generate_api_secret!
    update_attributes(api_secret: SecureRandom.uuid)
  end

  def remove_api_key!
    update_attributes(api_key: nil, api_secret: nil)
  end

  def currency_symbol
    CurrencyData.find(currency).symbol
  end

  def admin_link
    Rails.application.routes.url_helpers.edit_admin_distributor_url(id: id, host: Figaro.env.host)
  end

  def seen_recently?
    last_seen_at && last_seen_at > 30.minutes.ago
  end

  def sales_last_30_days
    @sales_last_30_days ||= begin
      amount = deductions.where("created_at > ?", 30.days.ago) \
               .where(deductable_type: "Delivery") \
               .map(&:amount).sum

      CrazyMoney.new(amount)
    end
  end

private

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def required_fields_for_webstore
    if active_webstore_changed? && active_webstore?
      errors.add(:active_webstore, "Need to have a delivery service setup before enabling the webstore") if delivery_services.count.zero?
      errors.add(:active_webstore, "Need to have a box setup before enabling the webstore") if boxes.count.zero?
    end
  end

  def validate_parameter_name
    return if parameter_name.nil?

    if Distributor.parameterize_name(parameter_name) != parameter_name
      errors.add(:parameter_name, "contains invalid characters")
    end
  end

  def check_emails
    if self.email
      self.email.strip!
      self.email.downcase!
    end

    self.support_email = self.email if self.support_email.blank?
  end

  def send_welcome_email
    DistributorMailer.welcome(self).deliver
  end

  def messaging
    @messaging ||= Distributor.messaging_class.new(self)
  end

  def self.messaging_class
    Messaging::Distributor
  end

  def validate_require_phone
    if require_phone && !collect_phone
      errors.add :require_phone, "You must collect the phone if you want to require it."
    end
  end

  def validate_require_delivery_note
    if require_delivery_note && !collect_delivery_note
      errors.add :require_delivery_note, "You must collect the delivery note if you want to require it."
    end
  end

  # This is meant to be run within console for dev work via Distributor.send(:travel_forward_a_day)
  # This will simulate the cron jobs each hour and move the time forward 1 day. It is designed to
  # be run repeatedly to move forward a day at a time
  def self.travel_forward_a_day(day = 1)
    # :nocov:
    @@original_time ||= Time.current
    @@advanced ||= 0
    (24 * day).times.each do |h|
      h += 1 # start at 1, not 0

      Delorean.time_travel_to(@@original_time + (@@advanced * day.days) + h.hours)
      Jobs.run_hourly
    end
    @@advanced += day
    # :nocov:
  end
end
