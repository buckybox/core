class Address < ActiveRecord::Base
  belongs_to :customer, :inverse_of => :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :delivery_note

  validates_presence_of :customer, :address_1, :suburb, :city, :postcode
end
