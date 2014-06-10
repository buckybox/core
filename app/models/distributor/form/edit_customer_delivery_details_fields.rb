require 'active_support/concern'
require_relative "../form"

module Distributor::Form::EditCustomerDeliveryDetailsFields

  extend ActiveSupport::Concern
  include Distributor::Form

  included do

    attribute :delivery_service,  Integer
    attribute :address_1,         String
    attribute :address_2,         String
    attribute :suburb,            String
    attribute :city,              String
    attribute :postcode,          String
    attribute :delivery_note,     String

    def_delegators :distributor,
      :require_address_1?,
      :require_address_2?,
      :require_suburb?,
      :require_city?,
      :require_postcode?,
      :collect_delivery_note?,
      :require_delivery_note?,
      :delivery_services

    validates_presence_of :delivery_service
    validates_presence_of :address_1,      if: -> { require_address_1? }
    validates_presence_of :address_2,      if: -> { require_address_2? }
    validates_presence_of :suburb,         if: -> { require_suburb? }
    validates_presence_of :city,           if: -> { require_city? }
    validates_presence_of :postcode,       if: -> { require_postcode? }
    validates_presence_of :delivery_note,  if: -> { require_delivery_note? }

  protected

    def assign_attributes(attributes)
      @delivery_service = attributes["delivery_service"] || customer.delivery_service
      @address_1        = attributes["address_1"]        || address.address_1
      @address_2        = attributes["address_2"]        || address.address_2
      @suburb           = attributes["suburb"]           || address.suburb
      @city             = attributes["city"]             || address.city
      @postcode         = attributes["postcode"]         || address.postcode
      @delivery_note    = attributes["delivery_note"]    || address.delivery_note
    end

    def delivery_details_customer_args
      {
        delivery_service:  delivery_service,
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
