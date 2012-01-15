class Customer < ActiveRecord::Base
  include PgSearch

  has_one :address, :dependent => :destroy, :inverse_of => :customer
  has_one :account, :dependent => :destroy

  has_many :orders, :through => :account
  has_many :payments, :through => :account
  has_many :deliveries, :through => :orders

  belongs_to :distributor
  belongs_to :route

  pg_search_scope :search,
    :against => [:first_name, :last_name, :email, :number],
    :associated_against => {
    :address => [:address_1, :address_2, :suburb, :city, :postcode, :delivery_note]
  },
    :using => {
    :tsearch => {:prefix => true}
  }

  before_create :initialize_number
  after_create :create_account
  after_create :trigger_new_customer

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :first_name, :last_name, :email, :phone, :name, :distributor_id, :distributor, :route

  validates_presence_of :first_name, :email, :distributor, :route
  validates_uniqueness_of :email, :scope => :distributor_id
  validates_uniqueness_of :number, :scope => :distributor_id

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(name)
    self.first_name, self.last_name = name.split(" ")
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

  def create_account
    Account.create(:customer_id => id, :distributor_id => distributor_id)
  end

  def trigger_new_customer
    Event.trigger(distributor_id, Event::EVENT_TYPES[:customer_new], {:event_category => "customer", :customer_id => id})
  end
end
