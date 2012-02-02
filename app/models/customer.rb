class Customer < ActiveRecord::Base
  include PgSearch

  belongs_to :distributor
  belongs_to :route

  has_one :address, :dependent => :destroy, :inverse_of => :customer
  has_one :account, :dependent => :destroy

  has_many :orders, :through => :account
  has_many :payments, :through => :account
  has_many :deliveries, :through => :orders

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable

  acts_as_taggable

  pg_search_scope :search,
    :against => [:first_name, :last_name, :email, :number],
    :associated_against => {
    :address => [:address_1, :address_2, :suburb, :city, :postcode, :delivery_note]
  },
    :using => {
    :tsearch => {:prefix => true}
  }

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :first_name, :last_name, :email, :phone, :name, :distributor_id, :distributor,
    :route, :route_id, :password, :remember_me, :tag_list

  validates_presence_of :first_name, :email, :distributor, :route
  validates_uniqueness_of :email, :scope => :distributor_id
  validates_uniqueness_of :number, :scope => :distributor_id
  validates_associated :account
  validates_associated :address

  before_validation :randomize_password_if_not_present

  before_create :initialize_number
  before_create :setup_account
  before_create :setup_address

  before_save :downcase_email

  after_create :trigger_new_customer

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

  def self.random_string(len = 10)
    # generate a random password consisting of strings and digits
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size - 1)] }
    return newpass
  end 

  private

  def initialize_number
    if self.number.nil?
      number = rand(1000000)
      safety = 1
      while(self.distributor.customers.find_by_number(number.to_s).present? && safety < 100) do
        number += 1
        safety += 1
        number = rand(1000000) if safety.modulo(10) == 0
      end
      if safety > 99
        throw "unable to assign customer number"
      end
      self.number = number.to_s
    end
  end

  def randomize_password_if_not_present
    randomize_password unless encrypted_password.present?
  end

  def setup_account
    self.build_account
  end

  def setup_address
    self.build_address
  end

  def trigger_new_customer
    Event.trigger(distributor_id, Event::EVENT_TYPES[:customer_new], {event_category: "customer", customer_id: id})
  end

  def downcase_email
    self.email.downcase! if self.email
  end
end
