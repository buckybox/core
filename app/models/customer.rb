class Customer < ActiveRecord::Base
  include PgSearch

  has_one :address, :dependent => :destroy, :inverse_of => :customer

  has_many :accounts, :dependent => :destroy
  has_many :orders, :dependent => :destroy
  has_many :payments, :dependent => :destroy

  pg_search_scope :search, 
    :against => [:first_name, :last_name, :email], 
    :associated_against => {
      :address => [:address_1, :address_2, :suburb, :city, :postcode, :delivery_note]
    },
    :using => {
      :tsearch => {:prefix => true}
    }

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :first_name, :last_name, :email, :phone, :name

  validates_presence_of :first_name, :last_name, :email
  validates_uniqueness_of :email

  def name
    "#{first_name} #{last_name}".strip
  end

  def name=(name)
    self.first_name, self.last_name = name.split(" ")
  end
end
