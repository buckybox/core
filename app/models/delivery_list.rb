FutureDeliveryList = Struct.new(:date, :deliveries)

class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, dependent: :destroy

  attr_accessible :distributor, :distributor_id, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, scope: :distributor_id

  default_scope order(:date)

  def self.collect_lists(distributor, start_date, end_date)
    result = DeliveryList.includes(deliveries: {package: {customer: {address: {}}}}).where(date:start_date..end_date, distributor_id: distributor.id).to_a

    if end_date.future?
      future_start_date = start_date
      future_start_date = (result.last.date + 1.day) if result.last

      (future_start_date..end_date).each do |date|
        result << collect_list(distributor, date)
      end
    end

    return result
  end

  def self.collect_list(distributor, date)
    date_orders = []
    wday = date.wday
    
    order_ids = Bucky::Sql.order_ids(distributor, date)
    date_orders = distributor.orders.active.where(id: order_ids).includes({ account: {customer: {address:{}, deliveries: {delivery_list: {}}}}, order_extras: {}, box: {}})

    # This emulates the ordering when lists are actually created
    FutureDeliveryList.new(date, date_orders.sort { |a,b|
      comp = a.dso(wday) <=> b.dso(wday)
      comp.zero? ? (b.created_at <=> a.created_at) : comp
    })
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
      position = package.order.dso(date.wday)
      packages[position] = [] unless packages[position]
      packages[position] << package
    end

    packages = packages.sort.map{ |key, value| value }.flatten

    packages.each do |package|
      order = package.order
      route = order.route

      # need to pass route as well or the position scope for this delivery list is not set properly
      delivery = delivery_list.deliveries.find_or_create_by_package_id(package.id, order: order, route: route)

      delivery.update_dso
      delivery.save! if delivery.changed?
    end

    return delivery_list
  end

  def reposition(delivery_order)
    # Assuming all routes are from the same route, if not it will fail on match anyway
    first_delivery = Delivery.find(delivery_order.first)
    route_id = first_delivery.route_id
    day = first_delivery.delivery_list.date.wday

    raise 'Your delivery ids do not match' if delivery_order.map(&:to_i).sort != deliveries.where(route_id: route_id).select(:id).map(&:id).sort

    # Don't know an easy way to preload like this in Rails, but load up all deliveries matching on id, PRESERVING the order of the ids thru to the deliveries array, VERY IMPORTANT
    deliveries_cache = Delivery.where(id: delivery_order).includes(:address).inject({}){|cache, d| cache.merge!(d.id => d)}
    ordered_address_hashes = []
    delivery_order.each do |id|
      ordered_address_hashes << deliveries_cache[id.to_i].address.address_hash if deliveries_cache[id.to_i]
    end

    master = DeliverySequenceOrder.where(route_id: route_id, day: day).ordered.collect(&:address_hash).uniq
    new_master_list = Bucky::Dso::List.sort(master, ordered_address_hashes.uniq) #Assuming .uniq is stable to the order
    DeliverySequenceOrder.update_ordering(new_master_list, route_id, day)

    return true
  end

  def mark_all_as_auto_delivered
    result = true
    deliveries.ordered.each { |delivery| result &= Delivery.auto_deliver(delivery) }
    return result
  end

  def has_deliveries?
    deliveries.count.zero?
  end

  def all_finished?
    deliveries.pending.count.zero?
  end

  def get_delivery_number(delivery)
    throw "This isn't my delivery" if delivery.delivery_list_id != self.id

    delivery_to_same_address = deliveries(true).select{|d| d.address_hash == delivery.address_hash && d.id != delivery.id}.first

    if delivery_to_same_address
      delivery_to_same_address.delivery_number
    else
      @delivery_number ||= {}
      last_delivery = deliveries(true).where(route_id: delivery.route.id).order(:delivery_number).last
      @delivery_number[self.id] = last_delivery.delivery_number if last_delivery
      @delivery_number[self.id] ||= 0
      @delivery_number[self.id] += 1
    end
  end

  def archived?
    date.past?
  end

  def quantity_for(route_id)
    if route_id.nil?
      Package.sum(:archived_order_quantity, joins: :deliveries, conditions: {deliveries: {delivery_list_id: id}})
    else
      Package.sum(:archived_order_quantity, joins: :deliveries, conditions: {deliveries: {delivery_list_id: id, route_id: route_id}})
    end
  end
end
