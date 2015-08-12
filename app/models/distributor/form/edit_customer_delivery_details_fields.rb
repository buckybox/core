require 'active_support/concern'
require_relative "../form"

module Distributor::Form::EditCustomerDeliveryDetailsFields
  extend ActiveSupport::Concern
  include Distributor::Form
  include Customer::AddressValidations

  included do
    attribute :delivery_service_id, Integer

    delegate :collect_delivery_note?, :delivery_services, to: :distributor

    validates_presence_of :delivery_service_id

  protected

    def assign_attributes(attributes)
      @delivery_service_id = attributes["delivery_service_id"] || customer.delivery_service_id
      @address_1           = attributes["address_1"] || address.address_1
      @address_2           = attributes["address_2"] || address.address_2
      @suburb              = attributes["suburb"] || address.suburb
      @city                = attributes["city"] || address.city
      @postcode            = attributes["postcode"] || address.postcode
      @delivery_note       = attributes["delivery_note"] || address.delivery_note
    end

    def delivery_details_customer_args
      {
        delivery_service_id: delivery_service_id,
      }
    end

    def delivery_details_address_args
      {
        address_1:      address_1,
        address_2:      address_2,
        suburb:         suburb,
        city:           city,
        postcode:       postcode,
        delivery_note:  delivery_note,
      }
    end
  end
end
