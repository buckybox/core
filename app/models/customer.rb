class Customer < ActiveRecord::Base
  include PgSearch

  belongs_to :distributor
  belongs_to :route

  has_one :address, dependent: :destroy, inverse_of: :customer
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

  validates_presence_of :first_name, :email, :distributor, :route, :discount
  #validates_uniqueness_of :email #This is done within Devise, left here to remind you
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

  def new?
    deliveries.size == 1
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
