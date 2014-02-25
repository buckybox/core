class DeliveryList < ActiveRecord::Base
  belongs_to :distributor

  has_many :deliveries, dependent: :destroy

  attr_accessible :distributor, :distributor_id, :date

  validates_presence_of :distributor, :date
  validates_uniqueness_of :date, scope: :distributor_id

  default_scope order(:date)

  def self.collect_list(distributor, date, options = {})
    date_orders = []
    wday = date.wday

    order_ids = options[:order_ids] || Bucky::Sql.order_ids(distributor, date)
    date_orders = distributor.orders.active.where(id: order_ids).includes({ account: {customer: {address:{}, deliveries: {delivery_list: {}}}}, order_extras: {}, box: {}})

    # This emulates the ordering when lists are actually created
    FutureDeliveryList.new(date, date_orders.sort { |a,b|
      comp = a.dso(wday) <=> b.dso(wday)
      comp.zero? ? (b.created_at <=> a.created_at) : comp
    })
  end

  def ordered_deliveries(ids = nil)
    list_items = deliveries.ordered
    list_items = list_items.select { |item| ids.include?(item.id) } if ids
    list_items
  end

  def self.generate_list(distributor, date)
    packing_list  = PackingList.find_or_create_by_distributor_id_and_date(distributor.id, date)
    delivery_list = DeliveryList.find_or_create_by_distributor_id_and_date(distributor.id, date)

    # Collecting via packing list rather than orders so that delivery generation is explicitly
    # linked with packages.
    packages = {}

    # Determine the order of this delivery list based on previous deliveries
    packing_list.packages.each do |package|
      position = package.order.dso(date.wday)
      packages[position] = [] unless packages[position]
      packages[position] << package
    end

    packages = packages.sort.map{ |key, value| value }.flatten

    packages.each do |package|
      order = package.order
      delivery_service = order.delivery_service

      # need to pass delivery service as well or the position scope for this delivery list is not set properly
      delivery = delivery_list.deliveries.find_or_create_by_package_id(package.id, order: order, delivery_service: delivery_service)

      delivery.update_dso
      delivery.save! if delivery.changed?
    end

    return delivery_list
  end

  def reposition(delivery_order)
    # Assuming all delivery services are from the same delivery service, if not it will fail on match anyway
    first_delivery = Delivery.find(delivery_order.first)
    delivery_service_id = first_delivery.delivery_service_id
    day = first_delivery.delivery_list.date.wday

    raise 'Your delivery ids do not match' if delivery_order.map(&:to_i).sort != deliveries.where(delivery_service_id: delivery_service_id).select(:id).map(&:id).sort

    # Don't know an easy way to preload like this in Rails, but load up all deliveries matching on id, PRESERVING the order of the ids thru to the deliveries array, VERY IMPORTANT
    deliveries_cache = Delivery.where(id: delivery_order).includes(:address).inject({}){|cache, d| cache.merge!(d.id => d)}
    ordered_address_hashes = []
    delivery_order.each do |id|
      ordered_address_hashes << deliveries_cache[id.to_i].address.address_hash if deliveries_cache[id.to_i]
    end

    master = DeliverySequenceOrder.where(delivery_service_id: delivery_service_id, day: day).ordered.collect(&:address_hash).uniq
    new_master_list = Bucky::Dso::List.sort(master, ordered_address_hashes.uniq) #Assuming .uniq is stable to the order
    DeliverySequenceOrder.update_ordering(new_master_list, delivery_service_id, day)

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
    raise "This isn't my delivery" if delivery.delivery_list_id != self.id

    delivery_to_same_address = deliveries(true).select{|d| d.address_hash == delivery.address_hash && d.id != delivery.id}.first

    if delivery_to_same_address
      delivery_to_same_address.delivery_number
    else
      @delivery_number ||= {}
      last_delivery = deliveries(true).where(delivery_service_id: delivery.delivery_service.id).order(:delivery_number).last
      @delivery_number[self.id] = last_delivery.delivery_number if last_delivery
      @delivery_number[self.id] ||= 0
      @delivery_number[self.id] += 1
    end
  end

  def archived?
    date.past?
  end

  def quantity_for(delivery_service_id)
    if delivery_service_id.nil?
      Package.sum(:archived_order_quantity, joins: :deliveries, conditions: {deliveries: {delivery_list_id: id}})
    else
      Package.sum(:archived_order_quantity, joins: :deliveries, conditions: {deliveries: {delivery_list_id: id, delivery_service_id: delivery_service_id}})
    end
  end
end
