class Address < ActiveRecord::Base
  belongs_to :customer, inverse_of: :address

  attr_accessible :customer, :address_1, :address_2, :suburb, :city, :postcode, :delivery_note, :phone_1, :phone_2, :phone_3

  validates_presence_of :customer, :address_1, :city

  def join(join_with = ', ', options = {})
    result = [address_1]
    result << address_2 unless address_2.blank?
    result << suburb
    result << city

    if options[:with_postcode]
      result << postcode unless postcode.blank?
    end

    if options[:with_phone]
      result << "Phone 1: #{phone_1}" unless phone_1.blank?
      result << "Phone 2: #{phone_2}" unless phone_2.blank?
      result << "Phone 3: #{phone_3}" unless phone_3.blank?
    end

    return result.join(join_with).html_safe
  end
end
