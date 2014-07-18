require 'virtus'
require 'active_model/naming'
require 'active_model/conversion'
require 'active_model/validations'
require 'active_model/translation'

class Customer::Form

  extend Forwardable
  extend ActiveModel::Naming

  include Virtus.model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :customer

  def_delegators :customer,
    :id,
    :address,
    :distributor

  def initialize(attributes = {})
    @customer = attributes.delete("customer")
    super
    assign_attributes(attributes)
  end

  def persisted?
    true
  end

  def self.i18n_scope
    :virtus
  end

protected

  def assign_attributes(attributes)
    #No Op
  end

end
