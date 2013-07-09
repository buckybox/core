class Customer < ActiveRecord::Base
  include PgSearch

  belongs_to :distributor
  belongs_to :route

  has_one :address, dependent: :destroy, inverse_of: :customer, autosave: true
  has_one :account, dependent: :destroy

  has_many :events,       dependent: :destroy
  has_many :transactions, through: :account
  has_many :payments,     through: :account
  has_many :deductions,   through: :account
  has_many :orders,       through: :account
  has_many :deliveries,   through: :orders

  belongs_to :next_order, class_name: 'Order'

  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  acts_as_taggable

  accepts_nested_attributes_for :address

  monetize :balance_threshold_cents

  attr_accessible :address_attributes, :first_name, :last_name, :email, :name, :distributor_id, :distributor,
    :route, :route_id, :password, :password_confirmation, :remember_me, :tag_list, :discount, :number, :notes,
    :special_order_preference, :balance_threshold, :via_webstore, :address

  validates_presence_of :distributor_id, :route_id, :first_name, :email, :discount, :address
  validates_uniqueness_of :number, scope: :distributor_id
  validates_numericality_of :number, greater_than: 0
  validates_numericality_of :discount, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0
  validates_associated :account
  validates_associated :address

  before_validation :initialize_number, if: 'number.nil?'
  before_validation :random_password, unless: 'encrypted_password.present?'
  before_validation :discount_percentage
  before_validation :format_email

  before_save :set_balance_threshold, if: :new_record?
  before_save :update_halted_status, if: :balance_threshold_cents_changed?

  before_create :setup_account
  before_create :setup_address

  after_create :via_webstore_notifications, if: :via_webstore?

  after_save :update_next_occurrence # This could be more specific about when it updates

  delegate :separate_bucky_fee?, :consumer_delivery_fee, :default_balance_threshold_cents, :has_balance_threshold, to: :distributor
  delegate :currency, :send_email?, to: :distributor, allow_nil: true
  delegate :name, to: :route, prefix: true

  scope :ordered_by_next_delivery, lambda { order("CASE WHEN next_order_occurrence_date IS NULL THEN '9999-01-01' WHEN next_order_occurrence_date < '#{Date.current.to_s(:db)}' THEN '9999-01-01' ELSE next_order_occurrence_date END ASC, lower(customers.first_name) ASC, lower(customers.last_name) ASC") }
  scope :ordered, order("lower(customers.first_name) ASC, lower(customers.last_name) ASC")

  default_value_for :discount, 0
  default_value_for :balance_threshold_cents do |c|
    if c.distributor.present?
      c.distributor.default_balance_threshold_cents
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

  def self.generate_random_password(length = 12)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(length) { |i| newpass << chars[rand(chars.size - 1)] }
    return newpass
  end

  def self.next_number(distributor)
    existing_customers = distributor.customers
    result = 1

    unless existing_customers.count == 0
      max_number = distributor.customers.maximum(:number)
      result = max_number + 1
    end

    return result
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

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(name)
    self.first_name, self.last_name = name.split(" ")
  end

  def randomize_password
    self.password = Customer.generate_random_password
    self.password_confirmation = self.password
  end

  def import(c, c_route)
    self.update_attributes({
      first_name: c.first_name,
      last_name: c.last_name,
      email: c.email,
      route: c_route,
      discount: c.discount,
      number: c.number,
      notes: c.notes,
      address_attributes: {
        address_1: c.delivery_address_line_1,
        address_2: c.delivery_address_line_2,
        suburb: c.delivery_suburb,
        city: c.delivery_city,
        postcode: c.delivery_postcode,
        delivery_note: c.delivery_instructions,
        mobile_phone: c.mobile_phone,
        home_phone: c.home_phone,
        work_phone: c.work_phone
      }
    })

    self.tag_list = c.tags.join(", ")
    self.save! # Blow up on error so transaction is aborted

    self.account.currency = self.currency
    self.account.change_balance_to(c.account_balance, {description: "Inital CSV Import"})
    self.account.save! # Blow up on error so transaction is aborted

    self.import_boxes(c.boxes)
  end

  def import_boxes(c_boxes)
    c_boxes.each do |b|
      box = distributor.boxes.find_by_name(b.box_type)
      raise "Can't find Box '#{b.box_type}' for distributor with id #{id}" if box.blank?

      delivery_date = Time.zone.parse(b.next_delivery_date.to_s)
      raise "Date couldn't be parsed from '#{b.delivery_date}'" if delivery_date.blank?

      order = self.orders.build({
        box: box,
        quantity: 1,
        account: self.account,
        extras_one_off: b.extras_recurring?
      })
      account.route = self.route
      order.schedule_rule = if b.delivery_frequency == 'single'
                              ScheduleRule.one_off(delivery_date, ScheduleRule::DAYS.select{|day| b.delivery_days =~ /#{day.to_s}/i})
                            else
                              ScheduleRule.recur_on(delivery_date, ScheduleRule::DAYS.select{|day| b.delivery_days =~ /#{day.to_s}/i}, b.delivery_frequency.to_sym)
                            end

      order.activate

      order.import_extras(b.extras) unless b.extras.blank?
      order.save! # Blow up on error so transaction is aborted
    end
  end

  def <=>(b)
    self.name <=> b.name
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

  def halted?
    status_halted
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
    send_halted_email if email_rule.send_email?(self)
  end

  def orders_pending_package_creation?
    orders.any?{|o| o.pending_package_creation?}
  end

  def send_login_details
    if send_email?
      CustomerMailer.login_details(self).deliver
    else
      false
    end
  end

  def via_webstore_notifications
    Event.new_customer_webstore(self)
    CustomerMailer.raise_errors do
      self.send_login_details
    end
  end

  def send_halted_email
    if distributor.send_email? && distributor.send_halted_email?
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

  def account_balance
    account = account(true) # force reload

    if account.present?
      account.balance
    else
      Money.new(0, currency)
    end
  end

  def calculate_next_order(date=Date.current.to_s(:db))
    orders.active.select("orders.*, next_occurrence('#{date}', false, false, schedule_rules.*)").joins(:schedule_rule).reject{|sr| sr.next_occurrence.blank?}.sort_by(&:next_occurrence).first
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

  def address_changed
    distributor.notify_address_changed(self)
  end

private
  def reversal_transaction_ids
    reversed = payments.reversed
    reversed.pluck(:transaction_id) + reversed.pluck(:reversal_transaction_id)
  end

  def initialize_number
    self.number = Customer.next_number(self.distributor) unless self.distributor.nil?
  end

  def random_password
    randomize_password
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

class Customer::EmailRule
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
