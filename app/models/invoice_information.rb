class InvoiceInformation < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :gst_number, :billing_address_1, :billing_address_2, :billing_suburb, :billing_city,
    :billing_postcode, :phone

  validates_presence_of :distributor_id, :gst_number, :billing_address_1, :billing_suburb, :billing_city,
    :billing_postcode, :phone

  # TODO: Consider moving this out to a addressable module
  def join(join_with = ', ', options = {})
    result = [billing_address_1]
    result << billing_address_2 unless billing_address_2.blank?
    result << billing_suburb
    result << billing_city

    if options[:with_postcode]
      result << billing_postcode unless billing_postcode.blank?
    end

    result << "Phone: #{phone}" unless phone.blank? if options[:with_phone]

    return result.join(join_with).html_safe
  end
end
