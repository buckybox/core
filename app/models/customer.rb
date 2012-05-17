class Customer < ActiveRecord::Base
  include PgSearch

  belongs_to :distributor
  belongs_to :route

  has_one :address, dependent: :destroy, inverse_of: :customer, autosave: true
  has_one :account, dependent: :destroy

  has_many :events
  has_many :transactions, through: :account
  has_many :payments,     through: :account
  has_many :orders,       through: :account
  has_many :deliveries,   through: :orders

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  acts_as_taggable

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :first_name, :last_name, :email, :name, :distributor_id, :distributor,
    :route, :route_id, :password, :password_confirmation, :remember_me, :tag_list, :discount, :number, :notes

  validates_presence_of :distributor_id, :route_id, :first_name, :email, :discount
  validates_uniqueness_of :number, scope: :distributor_id
  validates_numericality_of :number, greater_than: 0
  validates_numericality_of :discount, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0
  validates_associated :account
  validates_associated :address

  before_validation :initialize_number, if: 'number.nil?'
  before_validation :randomize_password_if_not_present
  before_validation :discount_percentage
  before_validation :format_email

  before_create :setup_account
  before_create :setup_address

  after_create :trigger_new_customer

  default_scope order(:first_name)

  pg_search_scope :search,
    against: [ :first_name, :last_name, :email ],
    associated_against: {
      address: [ :address_1, :address_2, :suburb, :city, :postcode, :delivery_note ]
    },
    using: { tsearch: { prefix: true } }

  def self.random_string(len = 10)
    # generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size - 1)] }
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
    self.password = Customer.random_string(12)
    self.password_confirmation = password
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
        phone_1: c.phone_1,
        phone_2: c.phone_2
      }
    })

    self.tag_list = c.tags.join(", ")
    self.save! # Blow up on error so transaction is aborted

    self.account.change_balance_to(c.account_balance, {description: "Inital CSV Import"})
    self.account.save! # Blow up on error so transaction is aborted

    self.import_boxes(c.boxes)
  end

  def import_boxes(c_boxes)
    c_boxes.each do |b|
      box = distributor.boxes.find_by_name(b.box_type)
      raise "Can't find Box '#{b.box_type}' for distributor with id #{id}" if box.blank?

      delivery_date = Time.zone.parse(b.next_delivery_date)
      raise "Date couldn't be parsed from '#{b.delivery_date}'" if delivery_date.blank?

      delivery_day_numbers = Route.delivery_day_numbers(b.delivery_days.split(',').collect{|d| d.strip.downcase.to_sym})

      order = self.orders.build({
        box: box,
        quantity: 1,
        likes: b.likes,
        dislikes: b.dislikes,
        account: self.account,
        extras_one_off: b.extras_recurring?
      })
      account.route = self.route
      order.create_schedule(delivery_date, b.delivery_frequency, delivery_day_numbers)
      order.activate

      order.import_extras(b.extras) unless b.extras.blank?
      order.save! # Blow up on error so transaction is aborted
    end
  end

  def <=>(b)
    self.name <=> b.name
  end

  def make_import_payment(amount, description, date)
    Payment.create!(distributor: distributor, account: account, amount: amount, kind: 'unspecified', source: 'import', description: "Import - #{date.to_s(:transaction)} #{description}")
  end

  private

  def initialize_number
    self.number = Customer.next_number(self.distributor)
  end

  def randomize_password_if_not_present
    randomize_password unless encrypted_password.present?
  end

  def discount_percentage
    self.discount = self.discount / 100.0 if self.discount > 1
  end

  def setup_account
    self.build_account if self.account.nil?
  end

  def setup_address
    self.build_address if self.address.nil?
  end

  def trigger_new_customer
    Event.new_customer(self)
  end

  def format_email
    if self.email
      self.email.strip!
      self.email.downcase!
    end
  end
end
