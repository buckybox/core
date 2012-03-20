FutureDeliveryList = Struct.new(:date, :deliveries)

class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, dependent: :destroy, order: :position

  attr_accessible :distributor, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, scope: :distributor_id

  default_scope order(:date)

  def self.collect_lists(distributor, start_date, end_date)
    result = distributor.delivery_lists.where(date:start_date..end_date).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      orders = distributor.orders.active

      (future_start_date..end_date).each do |date|
        date_orders = []

        orders.each { |order| date_orders << order if order.schedule.occurs_on?(date) }

        result << FutureDeliveryList.new(date, date_orders)
      end
    end

    return result
  end

  def self.generate_list(distributor, date)
    delivery_list = DeliveryList.find_or_create_by_distributor_id_and_date(distributor.id, date)
    packing_list = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    packages = {}

    # Determine the order of this delivery list based on previous deliveries
    packing_list.packages.each do |package|
      last_delivery = package.order.deliveries.last

      if last_delivery
        position = last_delivery.position
        packages[position] = [] unless packages[position]
        packages[position] << package
      else
        #sufficiantly large number to insure it is at the end
        packages[9999] = [] unless packages[9999]
        packages[9999] << package
      end
    end

    packages = packages.sort.map{ |key, value| value }.flatten

    packages.each do |package|
      order = package.order
      route = order.route
      # need to pass route as well or the position scope for this delivery list is not set properly
      delivery_list.deliveries.find_or_create_by_package_id(package.id, order: order, route: route)
    end

    return delivery_list
  end

  def mark_all_as_auto_delivered
    result = true

    deliveries.each { |delivery| result &= Delivery.auto_deliver(delivery) }

    return result
  end

  def has_deliveries?
    @has_deliveries ||= (deliveries.size == 0)
  end

  def all_finished?
    @all_finished ||= deliveries.all? { |delivery| delivery.status != 'pending' }
    has_deliveries? || @all_finished
  end
end
