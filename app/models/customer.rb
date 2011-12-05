class Customer < ActiveRecord::Base
  has_one :address, :dependent => :destroy, :inverse_of => :customer

  has_many :accounts, :dependent => :destroy
  has_many :orders, :dependent => :destroy
  has_many :payments, :dependent => :destroy

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :name, :email, :phone

  validates_presence_of :name, :email
  validates_uniqueness_of :email

  def name
    "#{first_name} #{last_name}"
  end
end
