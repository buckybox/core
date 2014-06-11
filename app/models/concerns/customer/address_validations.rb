require 'active_support/concern'

module Customer::AddressValidations

  extend ActiveSupport::Concern

  included do

    attribute :address_1,           String
    attribute :address_2,           String
    attribute :suburb,              String
    attribute :city,                String
    attribute :postcode,            String
    attribute :delivery_note,       String

    validates_presence_of :address_1,      if: -> { require_address_1 }
    validates_presence_of :address_2,      if: -> { require_address_2 }
    validates_presence_of :suburb,         if: -> { require_suburb }
    validates_presence_of :city,           if: -> { require_city }
    validates_presence_of :postcode,       if: -> { require_postcode }
    validates_presence_of :delivery_note,  if: -> { require_delivery_note }

    def delivery_service
      new_delivery_service || customer.delivery_service
    end

    def pickup_point?
      delivery_service.pickup_point?
    end

    def require_address_1
      !pickup_point? && distributor.require_address_1
    end

    def require_address_2
      !pickup_point? && distributor.require_address_2
    end

    def require_suburb
      !pickup_point? && distributor.require_suburb
    end

    def require_city
      !pickup_point? && distributor.require_city
    end

    def require_postcode
      !pickup_point? && distributor.require_postcode
    end

    def require_delivery_note
      !pickup_point? && distributor.require_delivery_note
    end

  private

    def new_delivery_service
      self.respond_to?(:delivery_service_id) && DeliveryService.find(delivery_service_id)
    end

  end
end
