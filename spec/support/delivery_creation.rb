DeliveryForDistributor = Struct.new(:delivery, :package)

def delivery_and_package_for_distributor(distributor, route, box, date, position)
  customer = Fabricate(:customer, distributor: distributor, route: route)
  account  = Fabricate(:account, customer: customer)
  order    = Fabricate(:active_order, account: account, box: box, schedule_rule: new_everyday_schedule)

  delivery_list = distributor.delivery_lists.where(date: date).first
  delivery_list ||= Fabricate(:delivery_list, distributor: distributor, date: date)

  packing_list = distributor.packing_lists.where(date: date).first
  packing_list ||= Fabricate(:packing_list, distributor: distributor, date: date)

  delivery_sequence_order = Fabricate(:delivery_sequence_order, address_hash: customer.address.address_hash, route: route, day: date.wday, position: position)

  package = Fabricate(:package, order: order, packing_list: packing_list)
  delivery = Fabricate(:delivery, order: order, delivery_list: delivery_list, route: route, package: package)

  DeliveryForDistributor.new(delivery.reload, package.reload)
end

def delivery_for_distributor(*args)
  delivery_and_package_for_distributor(*args).delivery
end
