class Address < ActiveRecord::Base
  belongs_to :customer, :inverse_of => :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :delivery_note

  validates_presence_of :customer, :address_1, :suburb, :city

  def join(join_with, options = {})
    result = [address_1]
    result << address_2 unless address_2.blank?
    result << suburb
    result << city
    result << postcode if options[:with_postcode]
    result << phone if options[:with_phone]

    return result.join(join_with)
  end
end
