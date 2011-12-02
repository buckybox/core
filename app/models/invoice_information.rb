class InvoiceInformation < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :gst_number, :billing_address_1, :billing_suburb, :billing_city, :billing_postcode

  validates_presence_of :distributor, :gst_number, :billing_address_1, :billing_suburb, :billing_city, :billing_postcode
end
