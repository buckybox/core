class Customer < ActiveRecord::Base
  include Bucky::Email
  include PgSearch

  belongs_to :distributor
  belongs_to :delivery_service

  has_one :address, dependent: :destroy, inverse_of: :customer, autosave: true
  has_one :account, dependent: :destroy

  has_many :events,       dependent: :destroy
  has_many :activities,   dependent: :destroy
  has_many :transactions, through: :account
  has_many :payments,     through: :account
  has_many :deductions,   through: :account
  has_many :orders,       through: :account
  has_many :deliveries,   through: :orders

  belongs_to :next_order, class_name: 'Order'

  acts_as_taggable

  accepts_nested_attributes_for :address

  monetize :balance_threshold_cents

  attr_accessible :address_attributes, :first_name, :last_name, :email, :name, :distributor_id, :distributor,
    :delivery_service, :delivery_service_id, :password, :password_confirmation, :remember_me, :tag_list, :discount, :number, :notes,
    :special_order_preference, :balance_threshold, :via_webstore, :address

  validates_presence_of :distributor_id, :delivery_service_id, :first_name, :email, :discount
  validates_uniqueness_of :number, scope: :distributor_id
  validates_numericality_of :number, greater_than: 0
  validates_numericality_of :discount, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0
  validates_associated :account

  before_validation :initialize_number, if: 'number.nil?'
  before_validation :randomize_password, unless: 'encrypted_password.present?'
  before_validation :discount_percentage
  before_validation :format_email

  before_save :set_balance_threshold, if: :new_record?
  before_save :update_halted_status, if: :balance_threshold_cents_changed?

  before_create :setup_account
  before_create :setup_address

  after_create :via_webstore_notifications, if: :via_webstore?
  after_create :librato_track

  after_save :update_next_occurrence # This could be more specific about when it updates

  delegate :locale, :separate_bucky_fee?, :consumer_delivery_fee, :default_balance_threshold_cents, :has_balance_threshold, to: :distributor
  delegate :currency, :send_email?, to: :distributor, allow_nil: true
  delegate :name, to: :delivery_service, prefix: true
  delegate :balance_at, to: :account

  scope :ordered_by_next_delivery, -> { order("CASE WHEN next_order_occurrence_date IS NULL THEN '9999-01-01' WHEN next_order_occurrence_date < '#{Date.current.to_s(:db)}' THEN '9999-01-01' ELSE next_order_occurrence_date END ASC, lower(customers.first_name) ASC, lower(customers.last_name) ASC") }
  scope :ordered, order("lower(customers.first_name) ASC, lower(customers.last_name) ASC")

  # <HACK>
  # Scope authentication by distributor ID
  # More info: https://github.com/plataformatec/devise/wiki/How-to:-Scope-login-to-subdomain

  # 1. Disable uniqueness constraint added by
  #    https://github.com/plataformatec/devise/blob/master/lib/devise/models/validatable.rb
  #    and create our own scoped constraint
  def self.validates_uniqueness_of(*args)
    args.first == :email && !args.last.delete(:force) ? nil : super
  end
  validates_uniqueness_of :email, scope: :distributor_id, force: true

  # 2. Tell Devise to fetch distributor_id too with the *_keys options
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable,
    authentication_keys: [:email, :distributor_id],
    reset_password_keys: [:email, :distributor_id]

  # 3. Override Devise's method to scope by distributor_id
  def self.find_first_by_auth_conditions(warden_conditions)
    distributor_id = warden_conditions[:distributor_id].to_i

    customers = if warden_conditions[:email]
      if distributor_id.zero?
        # the login and lost_password (GET) forms without the distributor param
        where("email ILIKE ?", warden_conditions[:email])
      else
        # the login and lost_password (GET) forms with the distributor param
        where("email ILIKE ?", warden_conditions[:email]).where(distributor_id: warden_conditions[:distributor_id])
      end
    elsif warden_conditions[:reset_password_token]
      # the lost_password (POST) form which uses a token
      Array(super)
    else
      raise "Unexcepted authentication"
    end

    customer = customers.first if customers.one?

    if customer
      Librato.increment "bucky.customer.sign_in.success.from_model"
      Librato.increment "bucky.customer.sign_in.success.total"
    else
      Librato.increment "bucky.customer.sign_in.failure.from_model"
      Librato.increment "bucky.customer.sign_in.failure.total"
    end

    customer
  end
  # </HACK>

  default_value_for :discount, 0
  default_value_for :balance_threshold_cents do |customer|
    if customer.distributor.present?
      customer.distributor.default_balance_threshold_cents
    else
      0
    end
  end

  pg_search_scope :search,
    against: [ :first_name, :last_name, :email ],
    associated_against: {
      address: [ :address_1, :address_2, :suburb, :city, :postcode, :delivery_note ]
    },
    using: { tsearch: { prefix: true } }

  def self.next_number(distributor)
    max_number = distributor.customers.maximum(:number) || 0
    max_number + 1
  end

  def self.all_dynamic_tags
    {
      'halted'           => 'important',
      'negative-balance' => 'hidden'
    }.freeze
  end

  def self.all_dynamic_tags_as_a_list
    all_dynamic_tags.keys.freeze
  end

  def self.active
    Customer.joins(:orders).where("orders.active" => true).uniq
  end

  def dynamic_tags
    self.class.all_dynamic_tags.select do |tag|
      public_send(tag.questionize)
    end
  end

  def add_activity(type, options = {})
    initiator = options.delete(:initiator) || self
    Activity.add(self, initiator, type, options)
  end

  def recent_activities(limit = 12)
    activities.order("created_at DESC").first(limit)
  end

  def guest?
    false
  end

  def formated_number
    "%04d" % number
  end

  def badge
    "#{formated_number} #{name}"
  end

  def new?
    deliveries.size <= 1
  end

  def email_to
    sanitise_email_header "#{name} <#{email}>"
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(name)
    # TODO: eventually migrate to a single "full name" and add a second "what should we call you" field
    # http://www.w3.org/International/questions/qa-personal-names#singlefield
    ActiveSupport::Deprecation.warn("Customer#name= is deprecated", caller(2))

    self.first_name, self.last_name = name.split(" ", 2)
  end

  def randomize_password
    self.password = Devise.friendly_token.first(8)
    self.password_confirmation = self.password
  end

  def <=>(other)
    self.name <=> other.name
  end

  def labels
    tag_list.sort.join(", ")
  end

  def has_first_and_last_name?
    first_name.present? && last_name.present?
  end

  def order_with_next_delivery
    next_order
  end

  def next_delivery_time
    next_order_occurrence_date
  end

  def update_next_occurrence(date = nil)
    date ||= Date.current.to_s(:db)
    next_order = calculate_next_order(date)
    if next_order
      self.next_order = next_order
      self.next_order_id = next_order.id
      self.next_order_occurrence_date = next_order.next_occurrence
    else
      self.next_order = nil
      self.next_order_id = nil
      self.next_order_occurrence_date = nil
    end
    self
  end

  def can_deactivate_orders?
    distributor.customer_can_remove_orders?
  end

  def update_next_occurrence!
    update_next_occurrence
    save!
  end

  def update_halted_status!(new_balance_threshold_cents = nil, email_rule = Customer::EmailRule.only_pending_orders)
    self.balance_threshold_cents = new_balance_threshold_cents unless new_balance_threshold_cents.blank?
    update_halted_status(email_rule)
    save!
  end

  def update_halted_status(email_rule = Customer::EmailRule.only_pending_orders)
    if has_balance_threshold && account_balance <= balance_threshold
      halt!(email_rule)
    else
      unhalt!
    end
  end

  def halt!(email_rule = Customer::EmailRule.only_pending_orders)
    unless halted?
      Customer.transaction do
        self.status_halted = true
        save!

        create_halt_notifications(email_rule)
        halt_orders!
      end
    end
  end

  def unhalt!
    if halted?
      Customer.transaction do
        self.status_halted = false
        save!

        unhalt_orders!
      end
    end
  end

  alias_method :halted, def halted?
    status_halted
  end

  def active?
    !active_orders.empty?
  end

  def active_orders
    orders.active
  end

  def halt_orders!
    ScheduleRule.update_all({halted: true}, ["scheduleable_id IN (?) AND scheduleable_type = 'Order'", orders.collect(&:id)])
    update_next_occurrence!
  end

  def unhalt_orders!
    ScheduleRule.update_all({halted: false}, ["scheduleable_id IN (?) AND scheduleable_type = 'Order'", orders.collect(&:id)])
    update_next_occurrence!
  end

  def create_halt_notifications(email_rule = Customer::EmailRule.only_pending_orders)
    Event.customer_halted(self)
    queue_halted_email if email_rule.send_email?(self)
  end

  def orders_pending_package_creation?
    orders.any?{|o| o.pending_package_creation?}
  end

  def send_login_details
    send_email? ? CustomerMailer.login_details(self).deliver : false
  end

  def via_webstore_notifications
    Event.new_webstore_customer(self) if distributor.notify_for_new_webstore_customer

    CustomerMailer.raise_errors do
      self.send_login_details
    end
  end

  def queue_halted_email
    # automatic delivery happens around 11pm which triggers the halted check
    # some distributors doing late deliveries input COD the next day
    # that's why we wait 23 hours before actually sending the email to customers
    delay(
      run_at: 23.hours.from_now,
      priority: Figaro.env.delayed_job_priority_low,
      queue: "#{__FILE__}:#{__LINE__}",
    ).send_halted_email
  end

  def send_halted_email
    if distributor.send_email? && distributor.send_halted_email? && halted?
      CustomerMailer.orders_halted(self).deliver
    end
  end

  def remind_customer_is_halted
    if distributor.send_email? && distributor.send_halted_email?
      CustomerMailer.remind_orders_halted(self).deliver
    end
  end

  def set_balance_threshold
    self.balance_threshold_cents = default_balance_threshold_cents unless balance_threshold_cents_changed?
  end

  def account_balance(reload: true)
    account = account(reload)

    account.present? ? account.balance : CrazyMoney.zero
  end

  def negative_balance?
    account_balance(reload: false).negative?
  end

  def calculate_next_order(date = Date.current.to_s(:db))
    calculate_next_orders(date).first
  end

  # next orders scheduled on `date` and later
  def calculate_next_orders(date = Date.current.to_s(:db))
    orders.active.select("orders.*, next_occurrence('#{date}', false, false, schedule_rules.*)")
      .joins(:schedule_rule).reject { |sr| sr.next_occurrence.blank? }.sort_by(&:next_occurrence)
  end

  def has_yellow_deliveries?
    orders.any?(&:has_yellow_deliveries?)
  end

  def last_paid
    r_ids = reversal_transaction_ids
    last_payment = transactions.payments
    if r_ids.present?
      last_payment = last_payment.where(["transactions.id not in (?)", r_ids])
    end
    last_payment = last_payment.ordered_by_display_time.first

    last_payment.present? ? last_payment.display_time : nil
  end

  def send_address_change_notification
    distributor.notify_address_changed(self)
  end

  def update_address(address_params, opts = {})
    opts.reverse_update({notify_distributor: false})

    if opts[:notify_distributor]
      address.update_with_notify(address_params, self)
    else
      address.update_attributes(address_params)
    end
  end

  def via_webstore!
    self.via_webstore = true
  end

  def uses_pickup_point?
    delivery_service.try(:pickup_point)
  end

private

  def librato_track
    Librato.increment "bucky.customer.create"
  end

  def reversal_transaction_ids
    reversed = payments.reversed
    reversed.pluck(:transaction_id) + reversed.pluck(:reversal_transaction_id)
  end

  def initialize_number
    self.number = Customer.next_number(self.distributor) unless self.distributor.nil?
  end

  def discount_percentage
    self.discount = self.discount / 100.0 if self.discount.present? && self.discount > 1
  end

  def setup_account
    self.build_account if self.account.nil?
  end

  def setup_address
    self.build_address if self.address.nil?
  end

  def format_email
    if self.email
      self.email.strip!
      self.email.downcase!
    end
  end
end

class Customer
  class EmailRule
    def self.all
      @all ||= EmailRule.new(:all)
    end

    def self.only_pending_orders
      @only_pending_orders ||= EmailRule.new(:only_pending_orders)
    end

    def self.no_email
      @no_email ||= EmailRule.new(:no_email)
    end

    attr_writer :type

    def initialize(type)
      self.type = type
    end

    def send_email?(customer)
      case type
      when :no_email
        false
      when :only_pending_orders
        customer.orders_pending_package_creation?
      when :all
        true
      end
    end

  private

    def type
      @type
    end
  end
end
