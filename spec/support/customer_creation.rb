def customer_with(args={})
  distributor = Fabricate(:distributor)
  delivery_service = Fabricate(:delivery_service, name: args[:delivery_service], distributor: distributor)
  customer = Fabricate(:customer,
    first_name: args[:first_name],
    last_name: args[:last_name],
    number: args[:number],
    email: args[:email],
    balance_threshold_cents: args[:minimum_balance],
    discount: args[:discount],
    sign_in_count: args[:sign_in_count],
    notes: args[:notes],
    special_order_preference: args[:special_order_preference],
    tag_list: args[:labels],
    distributor: distributor,
    delivery_service: delivery_service,
    )
  customer.address.attributes = {
    address_1: args[:address_1],
    address_2: args[:address_2],
    suburb: args[:suburb],
    city: args[:city],
    postcode: args[:postcode],
    delivery_note: args[:delivery_note],
    mobile_phone: args[:mobile_phone],
    home_phone: args[:home_phone],
    work_phone: args[:work_phone]
  }
  account = customer.account
  account.change_balance_to(args[:account_balance])
  account.reload
  customer
end
