FutureDeliveryList = Struct.new(:date, :deliveries)

class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, dependent: :destroy, order: :position

  attr_accessible :distributor, :distributor_id, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, scope: :distributor_id

  default_scope order(:date)

  def self.collect_lists(distributor, start_date, end_date)
    result = DeliveryList.includes(deliveries: {package: {customer: {address: {}}}}).where(date:start_date..end_date, distributor_id: distributor.id).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      orders = distributor.orders.active.includes({ account: {customer: {address:{}, deliveries: {delivery_list: {}}}}, order_extras: {}, box: {}})

      (future_start_date..end_date).each do |date|
        date_orders = []
        wday = date.wday

        orders.each { |order| date_orders << order if order.schedule.occurs_on?(date) }

        # This emulates the ordering when lists are actually created
        date_orders = date_orders.sort_by do |order|
          delivery = DeliveryList.last_week_delivery(wday, order.customer.deliveries)
          delivery ? delivery.position : 9999
        end

        result << FutureDeliveryList.new(date, date_orders)
      end
    end

    return result
  end

  def self.generate_list(distributor, date)
    packing_list  = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)
    delivery_list = DeliveryList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    # Collecting via packing list rather than orders so that delivery generation is explicitly
    # linked with packages.
    packages = {}
    current_wday = delivery_list.date.wday

    # Determine the order of this delivery list based on previous deliveries
    packing_list.packages.each do |package|
      previous_deliveries = package.customer.deliveries

      # Look back only on the same day of the week as routes are generally sorted by days of the week
      last_delivery = DeliveryList.last_week_delivery(current_wday, previous_deliveries)

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

  def reposition(delivery_order)
    # Assuming all routes are from the same route, if not it will fail on match anyway
    route_id = Delivery.find(delivery_order.first).route_id
    existing_ids = deliveries.where(route_id:route_id).map(&:id)

    raise 'Your delivery ids do not match' if delivery_order.map(&:to_i).sort != existing_ids.sort

    all_saved = true

    Delivery.transaction do
      delivery_order.each_with_index do |delivery_id, index|
        delivery = deliveries.find(delivery_id)
        all_saved &= delivery.reposition!(index + 1)
      end
    end

    return all_saved
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
    @all_finished ||= !deliveries.any? { |d| d.pending? }
    return has_deliveries? || @all_finished
  end

  private

  def self.last_week_delivery(day_of_the_week, deliveries)
    deliveries.select{ |d| d.date.wday == day_of_the_week }.sort{ |a,b| a.date <=> b.date }.last
  end
end
