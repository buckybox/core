Fabricator(:delivery) do
  order!
  delivery_list!
  route!
  package!
end

def delivery_for_distributor(distributor, route, box, date, position)
  customer = Fabricate(:customer, distributor: distributor, route: route)
  account = Fabricate(:account, customer: customer)
  order = Fabricate(:active_order, account: account, box: box)
  delivery_list = distributor.delivery_lists.where(date: date).first
  delivery = Fabricate(:delivery, order: order, delivery_list: delivery_list, route: route)
  delivery_sequence_order = Fabricate(:delivery_sequence_order, address: customer.address, route: route, day: date.wday, position: position)
  delivery.reload
end
