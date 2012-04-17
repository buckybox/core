class InvoiceInformation < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :gst_number, :billing_address_1, :billing_address_2, :billing_suburb, :billing_city,
    :billing_postcode, :phone

  validates_presence_of :distributor_id, :gst_number, :billing_address_1, :billing_suburb, :billing_city,
    :billing_postcode, :phone
end
