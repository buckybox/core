class Distributor < ActiveRecord::Base
  has_one :bank_information,          dependent: :destroy
  has_one :invoice_information,       dependent: :destroy

  has_many :extras,                   dependent: :destroy
  has_many :boxes,                    dependent: :destroy
  has_many :routes,                   dependent: :destroy
  has_many :orders,                   dependent: :destroy, through: :boxes
  has_many :webstore_orders,          dependent: :destroy, through: :boxes
  has_many :deliveries,               dependent: :destroy, through: :orders
  has_many :payments,                 dependent: :destroy
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

  belongs_to :country

  DEFAULT_TIME_ZONE               = 'Wellington'
  DEFAULT_CURRENCY                = 'nzd'
  DEFAULT_ADVANCED_HOURS          = 18
  DEFAULT_ADVANCED_DAYS           = 3
  DEFAULT_AUTOMATIC_DELIVERY_HOUR = 18
  DEFAULT_AUTOMATIC_DELIVERY_DAYS = 1

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  mount_uploader :company_logo, CompanyLogoUploader
  mount_uploader :company_team_image, CompanyTeamImageUploader

  monetize :invoice_threshold_cents
  monetize :consumer_delivery_fee_cents

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :url, :company_logo, :company_logo_cache,
    :remove_company_logo, :company_team_image, :company_team_image_cache, :remove_company_team_image, :completed_wizard,
    :support_email, :invoice_threshold, :separate_bucky_fee, :advance_hour, :advance_days, :automatic_delivery_hour,
    :time_zone, :currency, :bank_deposit, :paypal, :bank_deposit_format, :country_id, :consumer_delivery_fee,
    :consumer_delivery_fee_cents, :active_webstore, :about, :details, :facebook_url

  validates_presence_of :country
  validates_presence_of :email
  validates_uniqueness_of :email
  validates_presence_of :name, on: :update
  validates_uniqueness_of :name, on: :update
  validates_numericality_of :advance_hour, greater_than_or_equal_to: 0
  validates_numericality_of :advance_days, greater_than_or_equal_to: 0
  validates_numericality_of :automatic_delivery_hour, greater_than_or_equal_to: 0
  validates_presence_of :bank_deposit_format, if: :bank_deposit?

  before_validation :parameterize_name
  before_validation :check_emails

  after_save :generate_required_daily_lists

  default_value_for :time_zone,               DEFAULT_TIME_ZONE
  default_value_for :currency,                DEFAULT_CURRENCY
  default_value_for :advance_hour,            DEFAULT_AUTOMATIC_DELIVERY_HOUR
  default_value_for :advance_days,            DEFAULT_ADVANCED_DAYS
  default_value_for :automatic_delivery_hour, DEFAULT_AUTOMATIC_DELIVERY_HOUR

  default_value_for :bank_deposit, true
  default_value_for :paypal, false
  default_value_for :invoice_threshold_cents, -500
  default_value_for :bucky_box_percentage, 0.0175
  default_value_for :bank_deposit_format, ImportTransactionList::FILE_FORMATS.first.last # Kiwibank

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

  def window_end_at
    days_to_generate = (advance_days - 1) # this is because we are including the start date
    window_start_from + days_to_generate.days
  end

  def generate_required_daily_lists
    start_date = window_start_from
    end_date   = window_end_at

    newest_list_date = packing_lists.last.date if packing_lists.last

    successful = true # assume all is good with the world

    if newest_list_date && (newest_list_date > end_date)
      # Only need to delete the difference
      start_date = end_date + 1.day
      end_date = newest_list_date

      (start_date..end_date).each do |date|
        # Seek and destroy (http://youtu.be/wLBpLz5ELPI?t=3m10s) the lists that are now out of range
        packing_list = packing_lists.find_by_date(date)
        successful &= packing_list.destroy unless packing_list.nil?

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

  def last_csv_format
    last_import = import_transaction_lists.order("created_at DESC").first
    last_import.present? ? last_import.file_format : nil
  end

  def supported_csv_formats
    result = ""
    result << ImportTransactionList::FILE_FORMATS.find{|name, code| code == bank_deposit_format}.first if bank_deposit?
    result << " or " if bank_deposit? && paypal?
    result << "Paypal" if paypal?
    result
  end

  def available_csv_formats_select
    select_options = []
    select_options << ImportTransactionList::FILE_FORMATS.find{|name, code| code == bank_deposit_format} if bank_deposit?
    select_options << ImportTransactionList::FILE_FORMATS.find{|name, code| code == "paypal"} if paypal?
    select_options
  end

  def show_payments_tab?
    available_csv_formats_select.present?
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
      Jobs.run_all
    end
    @@advanced += day
  end
end
