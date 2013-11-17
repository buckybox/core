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
      :id,
      :address

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
      result = customer.update_attributes(customer_args)
      result &&= address.update_attributes(address_args)
      result
    end

  protected

    def assign_attributes(attributes)
      #No Op
    end

    def customer_args
      {}
    end

    def address_args
      {}
    end

  end

end
