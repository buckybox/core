class Distributor < ActiveRecord::Base
  include Bucky::Email

  has_one :bank_information,          dependent: :destroy
  has_one :invoice_information,       dependent: :destroy
  has_one :localised_address,         dependent: :destroy, as: :addressable, autosave: true

  has_many :extras,                   dependent: :destroy
  has_many :boxes,                    dependent: :destroy
  has_many :routes,                   dependent: :destroy
  has_many :orders,                   dependent: :destroy, through: :boxes
  has_many :webstore_orders,          dependent: :destroy, through: :boxes
  has_many :deliveries,               dependent: :destroy, through: :orders
  has_many :payments,                 dependent: :destroy
  has_many :deductions,               dependent: :destroy
  has_many :customers,                dependent: :destroy, autosave: true # Want to save those customers added via import_customers
  has_many :accounts,                 dependent: :destroy, through: :customers
  has_many :invoices,                 dependent: :destroy, through: :accounts
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

  #Metrics
  has_many :distributor_metrics
  has_many :distributor_logins
  has_many :customer_logins
  has_many :customer_checkouts

  belongs_to :country

  DEFAULT_TIME_ZONE               = 'Wellington'
  DEFAULT_CURRENCY                = 'nzd'
  DEFAULT_ADVANCED_HOURS          = 18
  DEFAULT_ADVANCED_DAYS           = 3
  DEFAULT_AUTOMATIC_DELIVERY_HOUR = 18
  DEFAULT_AUTOMATIC_DELIVERY_DAYS = 1

  HUMANIZED_ATTRIBUTES = {
    email: "Account login email"
  }

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  acts_as_taggable

  mount_uploader :company_logo, CompanyLogoUploader
  mount_uploader :company_team_image, CompanyTeamImageUploader

  monetize :invoice_threshold_cents
  monetize :consumer_delivery_fee_cents
  monetize :default_balance_threshold_cents

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me,
    :name, :url, :company_logo, :company_logo_cache, :remove_company_logo,
    :company_team_image, :company_team_image_cache, :remove_company_team_image,
    :completed_wizard, :support_email, :invoice_threshold, :separate_bucky_fee,
    :advance_hour, :advance_days, :automatic_delivery_hour, :time_zone, :currency,
    :country_id, :consumer_delivery_fee, :consumer_delivery_fee_cents,
    :active_webstore, :about, :details, :facebook_url, :city,
    :customers_show_intro, :deliveries_index_packing_intro,
    :deliveries_index_deliveries_intro, :payments_index_intro,
    :customers_index_intro, :customer_can_remove_orders, :parameter_name,
    :default_balance_threshold, :has_balance_threshold,
    :spend_limit_on_all_customers, :send_email, :send_halted_email,
    :feature_spend_limit, :contact_name, :tag_list, :collect_phone,
    :require_address_1, :require_address_2, :require_suburb, :require_postcode,
    :require_phone, :require_city, :omni_importer_ids, :notes,
    :payment_cash_on_delivery, :payment_bank_deposit, :payment_credit_card,
    :keep_me_updated, :email_templates, :notify_address_change, :phone,
    :localised_address_attributes

  accepts_nested_attributes_for :localised_address

  validates_presence_of :country
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :name, on: :update
  validates_uniqueness_of :name, on: :update
  validates_numericality_of :advance_hour, greater_than_or_equal_to: 0
  validates_numericality_of :advance_days, greater_than_or_equal_to: 0
  validates_numericality_of :automatic_delivery_hour, greater_than_or_equal_to: 0
  validate :required_fields_for_webstore
  validate :payment_options_valid
  validate :validate_parameter_name

  before_validation :check_emails
  before_create :parameterize_name, if: 'parameter_name.nil?'
  after_create :send_welcome_email

  after_create :tracking_after_create

  after_save :generate_required_daily_lists
  after_save :update_halted_statuses
  after_save :tracking_after_save

  serialize :email_templates, Array

  default_value_for :time_zone,               DEFAULT_TIME_ZONE
  default_value_for :currency,                DEFAULT_CURRENCY
  default_value_for :advance_hour,            DEFAULT_AUTOMATIC_DELIVERY_HOUR
  default_value_for :advance_days,            DEFAULT_ADVANCED_DAYS
  default_value_for :automatic_delivery_hour, DEFAULT_AUTOMATIC_DELIVERY_HOUR

  default_value_for :invoice_threshold_cents, -500
  default_value_for :bucky_box_percentage, 0.0175
  default_value_for :notify_address_change, true

  scope :keep_updated, where(keep_me_updated: true)

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

          details = ["#{distributor.name}", "TZ #{distributor.time_zone} #{Time.current}"].join("\n")

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

  def self.update_next_occurrence_caches
    all.each do |distributor|
      distributor.use_local_time_zone do
        if Time.current.hour == distributor.automatic_delivery_hour
          CronLog.log("Updated next order caches for #{distributor.id} at local time #{Time.current.to_s(:pretty)}.")
          distributor.update_next_occurrence_caches 
        end
      end
    end
  end

  def email_from
    sanitise_email_header "#{name} <#{support_email}>"
  end

  def email_to
    sanitise_email_header "#{contact_name} <#{email}>"
  end

  def banks
    omni_importers.bank_deposit.pluck(:bank_name).uniq
  end

  def consumer_delivery_fee_cents
    if separate_bucky_fee?
      read_attribute(:consumer_delivery_fee_cents)
    else
      0
    end
  end

  def update_next_occurrence_caches(date=nil)
    use_local_time_zone do
      if Time.current.hour >= automatic_delivery_hour
        date ||= Date.current.tomorrow
      else
        date ||= Date.current
      end
      Bucky::Sql.update_next_occurrence_caches(self, date)
    end
  end

  def window_start_from
    # If we have missed the cutoff point add a day so we start generation from tomorrow
    Date.current + ( advance_hour < Time.current.hour ? 1 : 0 ).days
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

  # Find extra from import script, if given a box, limit it
  # to the boxes allowed extras
  def find_extra_from_import(e, box=nil)
    search_extras = []
    box = box.present? ? find_box_from_import(box) : nil

    if box.blank?
      search_extras = extras.alphabetically
    elsif box.extras_not_allowed?
      []
    else
      search_extras = box.extras.alphabetically
    end

    matches = search_extras.select{|extra| extra.match_import_extra?(e)}.
      collect{|extra_match| [extra_match.fuzzy_match(e),extra_match]}.
      select{|fuzzy_match| fuzzy_match.first > Extra::FUZZY_MATCH_THRESHOLD}. # Set a lower threashold which weeds out almost matches and force the data to be fixed.  Make the user go fix the csv file.
      sort{|a,b| b.first <=> a.first}

    match = if matches.size > 1 && matches.first.first == matches[1].first
      # At-least the first two matches have the same fuzzy_match (probably no unit set)
      # So return the first one alphabetically so that it is consistent
      matches.select{ |m| m.first == matches.first.first }. #Select those which have the same fuzzy_match
        collect(&:last). # discard the fuzzy_match number
        sort_by{|extra| "#{extra.name} #{extra.unit}"}.first # Sort alphabeticaly
    else
      matches.first.last if matches.first.present?
    end

    match
  end

  def find_box_from_import(box)
    if box.is_a?(Box) && box_ids.include?(box.id)
      box
    elsif box.is_a?(Bucky::Import::Box)
      boxes.find_by_name(box.box_type)
    else
      raise "Couldn't find the box #{box.inspect} for this distributor #{distributor.inspect}"
    end
  end

  def find_duplicate_import_transactions(date, description, amount)
    import_transactions.processed.not_duplicate.not_removed.where(transaction_date: date, description: description, amount_cents: (amount * 100).to_i)
  end

  def find_previous_match(description)
    import_transactions.processed.matched.not_removed.where(description: description).ordered.last
  end

  def supported_csv_formats
    omni_importers.collect{|o| o.name}.to_sentence({two_words_connector: ' or ', last_word_connector: ', or '})
  end

  def last_used_omni_importer(prefered=nil)
    prefered ||
      import_transaction_lists.order('created_at DESC').first.try(:omni_importer) ||
      omni_importers.ordered.first
  end

  def show_payments_tab?
    !omni_importers.count.zero?
  end

  def can_upload_payments?
    show_payments_tab? && import_transaction_lists.draft.count.zero?
  end

  def cache_key
    @cache_key ||= "#{id}/#{name}/#{updated_at}"
  end

  def invoice_for_range(start_date, end_date)
    use_local_time_zone do
      start = Date.parse(start_date)
      finish = Date.parse(end_date)

      delivered = delivery_lists.where(["date >= ? AND date <= ?", start.to_date, finish.to_date]).collect{|dl| dl.deliveries.delivered.size}.sum

      cancelled = delivery_lists.where(["date >= ? AND date <= ?", start.to_date, finish.to_date]).collect{|dl| dl.deliveries.cancelled.size}.sum

      value = delivery_lists.where(["date >= ? AND date <= ?", start.to_date, finish.to_date]).collect{|dl| dl.deliveries.delivered.count.zero? ? Money.new(0, currency) : dl.deliveries.delivered.collect{|w| w.package.price}.sum}.sum

      formatted = value == 0 ? Money.new(0, currency).format : value.format

      return {delivered: delivered,
      cancelled: cancelled,
      value: formatted}
    end
  end

  require 'csv'
  def transaction_history_report(from, to)
    csv_string = CSV.generate do |csv|
      csv << ["Date Transaction Occurred", "Date Transaction Processed", "Amount", "Description", "Customer Name", "Customer Number", "Customer Email", "Customer City", "Customer Suburb", "Customer Tags", "Discount"]

      transactions.where(["? <= display_time AND display_time < ?", from, to]).order('display_time DESC, created_at DESC').includes(account: {customer: {address: {}}}).each do |transaction|
        row = []
        row << transaction.created_at.to_s(:csv_output)
        row << transaction.display_time.to_s(:csv_output)
        row << transaction.amount
        row << transaction.description
        row << transaction.customer.name
        row << transaction.customer.number
        row << transaction.customer.email
        row << transaction.customer.address.city
        row << transaction.customer.address.suburb
        row << transaction.customer.tags.collect{|t| "\"#{t.name}\""}.join(", ")
        row << transaction.customer.discount

        csv << row
      end
    end

    return csv_string
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
    @spend_limit_on_all_customers = (val == '1')
  end

  def spend_limit_on_all_customers
    @spend_limit_on_all_customers
  end
  alias_method :spend_limit_on_all_customers?, :spend_limit_on_all_customers

  def send_email?
    send_email
  end

  def send_halted_email?
    send_email? && send_halted_email
  end

  def number_of_customers_emailed_after_update(spend_limit, update_existing)
    if update_existing
      customers.joins(:account).where(["accounts.balance_cents <= ? and customers.status_halted = 'f'", spend_limit]).select{|c| c.orders_pending_package_creation?}.size
    else
      customers.joins(:account).where("accounts.balance_cents <= customers.balance_threshold_cents and customers.status_halted = 'f'").select{|c| c.orders_pending_package_creation?}.size
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
    [country.try(:full_name), city].reject(&:blank?).join(', ')
  end

  def mark_seen_recently!
    touch(:last_seen_at) #No validations or callbacks are performed
  end

  def packing_list_by_date(date)
    PackingList.collect_list(self, date)
  end

  def delivery_list_by_date(date)
    list = delivery_lists.where(date: date).first
    list = DeliveryList.collect_list(self, date) if list.nil?
    list
  end

  def payment_options
    options = []
    options << ["Bank deposit", :bank_deposit] if payment_bank_deposit?
    options << ["Cash on delivery", :cash_on_delivery] if payment_cash_on_delivery?
    options
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

  def transactional_customer_count
    Bucky::Sql.transactional_customer_count(self)
  end

  def new_transactional_customer_count
    Bucky::Sql.transactional_customer_count(self, 1.week.ago.to_date)
  end

  def new_customer_count
    customers.where(["created_at >= ?", 1.week.ago]).count
  end

  def notify_address_changed(customer, notifier = Event)
    return false unless notify_address_change?
    notifier.customer_changed_address(customer)
  end

  def notify_on_halt
    true
  end

  def notify_for_new_webstore_customer
    true
  end

  def customers_for_export(customer_ids)
    data = customers.ordered.where(id: customer_ids)
    data.includes(route: {}, account: { route: {} }, next_order: { box: {} })
  end
  
  def track(action_name, occurred_at=Time.current)
    user = Intercom::User.find_by_user_id(self.id)
    user.custom_data["#{action_name}_at"] = occurred_at
    user.save
  end

private

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def required_fields_for_webstore
    if active_webstore_changed? && active_webstore?
      errors.add(:active_webstore, "Need bank information filled in before enabling the webstore") unless bank_information.present? && bank_information.valid?
      errors.add(:active_webstore, "Need to have a route setup before enabling the webstore") if routes.count.zero?
      errors.add(:active_webstore, "Need to have a box setup before enabling the webstore") if boxes.count.zero?
    end
  end

  def payment_options_valid
    errors.add(:payment_cash_on_delivery, "Must have at least one payment option selected") if payment_options.empty?
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

  def tracking_after_create
    ::Intercom::User.create(user_id: id, email: email, name: name, created_at: created_at, custom_data: {contact_name: contact_name, phone: phone})
  end

  def tracking_after_save
    return unless Rails.env.production?

    self.delay(
      priority: Figaro.env.delayed_job_priority_low
    ).update_tags
  end

  def send_welcome_email
    DistributorMailer.welcome(self).deliver
  end

  def update_tags
    tag_list.each do |tag_name|
      tag = nil
      begin
        tag = ::Intercom::Tag.find_by_name(tag_name)
      rescue Intercom::ResourceNotFound
        tag = ::Intercom::Tag.new
        tag.name = tag_name
      end
      tag.user_ids = [self.id.to_s]
      tag.color = 'blue'
      tag.tag_or_untag = 'tag'
      tag.save
    end
  end

  # This is meant to be run within console for dev work via Distributor.send(:travel_forward_a_day)
  # This will simulate the cron jobs each hour and move the time forward 1 day. It is designed to
  # be run repeatedly to move forward a day at a time
  def self.travel_forward_a_day(day=1)
    #every 1.hour do
    @@original_time ||= Time.current
    @@advanced ||= 0
    (24 * day).times.each do |h|
      h += 1 # start at 1, not 0

      Delorean.time_travel_to(@@original_time + (@@advanced*day.days) + h.hours)
      Jobs.run_hourly
    end
    @@advanced += day
  end
end
