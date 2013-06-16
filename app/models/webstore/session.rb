require_relative '../webstore'
require_relative 'order'
require_relative 'customer'

class Webstore::Session
  attr_reader :order
  attr_reader :customer

  def initialize(args)
    args      = defaults.merge(args)
    @order    = get_object(args[:order_class], args[:order_id])
    @customer = get_object(args[:customer_class], args[:customer_id])
  end

  def self.deserialize(args = {})
    new(args)
  end

  def serialize
    { order_id: order.id, customer_id: customer.id }
  end

private

  def get_object(object_class, id)
    object_class.find(id)
  end

  def defaults
    { order_class: Webstore::Order,  customer_class: Webstore::Customer }
  end
end
