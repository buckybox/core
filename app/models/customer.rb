class Customer < ActiveRecord::Base
  has_many :orders, :dependent => :destroy
  has_one :address, :dependent => :destroy, :inverse_of => :customer

  accepts_nested_attributes_for :address

  attr_accessible :address_attributes, :name, :email, :phone

  validates_presence_of :name, :email
  validates_uniqueness_of :email
end
