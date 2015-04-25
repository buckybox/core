require 'virtus'
require 'active_support/concern'
require 'active_model/naming'
require 'active_model/conversion'
require 'active_model/validations'
require 'active_model/translation'

module Distributor::Form
  extend ActiveSupport::Concern

  included do
    extend Forwardable
    extend ActiveModel::Naming

    include Virtus.model
    include ActiveModel::Conversion
    include ActiveModel::Validations

    attribute :distributor,  Integer
    attribute :customer,     Integer

    def_delegators :customer,
      :id

    def initialize(attributes = {})
      @distributor = attributes.delete(:distributor)
      @customer    = attributes.delete(:customer)
      super
      assign_attributes(attributes)
    end

    def persisted?
      true
    end

    def save
      return false unless valid?

      success = customer.update_attributes(customer_args) &&
        address.update_attributes(address_args)

      forward_errors_to_form customer
      forward_errors_to_form address

      success
    end

  protected

    def forward_errors_to_form model
      model.errors.each do |attribute, message|
        errors.add(attribute, message)
      end
    end

    def address
      @address ||= begin
        customer.address || Address.new
      end
    end

    def assign_attributes(_attributes)
      # No Op
    end

    def customer_args
      {}
    end

    def address_args
      {}
    end
  end
end
