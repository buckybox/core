require_relative '../webstore'
require_relative 'order'
require_relative 'customer'

class Webstore::Session
  attr_reader :order
  attr_reader :customer

  def self.find(id)
    session_persistance = Webstore::SessionPersistance.find_by_id(id)
    session_persistance.webstore_session
  end

  def self.find_or_create(id)
    id ? find(id) : new
  end

  def initialize(args = {})
    @order    = new_order(args)
    @customer = new_customer(args)
  end

  def save
    return 0 unless valid?
    session_persistance = Webstore::SessionPersistance.save(self)
    session_persistance.id
  end

private

  def valid?
    !order.nil?
  end

  def new_order(args)
    box_id = args[:box_id]
    default_hash = box_id ? { box_id: box_id } : {}
    Webstore::Order.new(args.fetch(:order, default_hash))
  end

  def new_customer(args)
    Webstore::Customer.new(args.fetch(:customer, {}))
  end
end
