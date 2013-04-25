class CsvGenerator
  attr_reader :data

  def initialize(data)
    @data = data
  end

  def generate
    CSV.generate do |csv|
      csv << csv_headers
      data.each { |export_item| csv << generate_row(export_item) }
    end
  end

  def csv_headers
    [
      'Delivery Route', 'Delivery Sequence Number', 'Delivery Pickup Point Name',
      'Order Number', 'Package Number', 'Delivery Date', 'Customer Number', 'Customer First Name',
      'Customer Last Name', 'Customer Phone', 'New Customer', 'Delivery Address Line 1', 'Delivery Address Line 2',
      'Delivery Address Suburb', 'Delivery Address City', 'Delivery Address Postcode', 'Delivery Note',
      'Box Contents Short Description', 'Box Type', 'Box Likes', 'Box Dislikes', 'Box Extra Line Items',
      'Price', 'Bucky Box Transaction Fee', 'Total Price', 'Customer Email', 'Customer Special Preferences',
      'Package Status', 'Delivery Status',
    ]
  end

protected

  def generate_row(export_item)
    order, package, delivery, customer = seperate_data_row(export_item)

    address          = get_address(package, order)
    package_or_order = package ? package : order

    [
      delivery_route(order),
      delivery_sequence_number(delivery),
      delivery_pickup_point_name(delivery),
      order_number(order),
      package_number(package),
      delivery_date(package),
      customer_number(customer),
      customer_first_name(customer),
      customer_last_name(customer),
      customer_phone(address),
      new_customer(customer),
      delivery_address_line_1(address),
      delivery_address_line_2(address),
      delivery_address_suburb(address),
      delivery_address_city(address),
      delivery_address_postcode(address),
      delivery_note(address),
      box_contents_short_description(package_or_order),
      box_type(package_or_order),
      box_likes(package_or_order),
      box_dislikes(package_or_order),
      box_extra_line_items(package_or_order),
      price(package_or_order),
      bucky_box_transaction_fee(package_or_order),
      total_price(package_or_order),
      customer_email(customer),
      customer_special_preferences(customer),
      package_status(package),
      delivery_status(delivery),
    ]
  end

  def get_address(package, order)
    package ? package.archived_address_details : order.address
  end

  def seperate_data_row(export_item)
    order = get_order(export_item)
    [
      order,
      get_package(export_item),
      get_delivery(export_item),
      get_customer(order)
    ]
  end

  def get_customer(order)
    order.customer
  end

  def delivery_route(order)
    order.route.name
  end

  def delivery_sequence_number(delivery)
     delivery.formated_delivery_number if delivery
  end

  #NOTE: Keeping this due to legacy CSV convention but nothing in system for it yet
  def delivery_pickup_point_name(delivery)
    nil
  end

  def order_number(order)
    order.id
  end

  def package_number(package)
    package.id
  end

  def delivery_date(package)
    package.date.strftime("%-d %b %Y")
  end

  def customer_number(customer)
    customer.number
  end

  def customer_first_name(customer)
    customer.first_name
  end

  def customer_last_name(customer)
    customer.last_name
  end

  def customer_phone(address)
    address.phone_1
  end

  def new_customer(customer)
    customer.new? ? 'NEW' : nil
  end

  def delivery_address_line_1(address)
    address.address_1
  end

  def delivery_address_line_2(address)
    address.address_2
  end

  def delivery_address_suburb(address)
    address.suburb
  end

  def delivery_address_city(address)
    address.city
  end

  def delivery_address_postcode(address)
    address.postcode
  end

  def delivery_note(address)
    address.delivery_note
  end

  def box_contents_short_description(package_or_order)
    package_or_order.short_code
  end

  def box_type(package_or_order)
    package_or_order.archived_box_name
  end

  def box_likes(package_or_order)
    package_or_order.archived_substitutions
  end

  def box_dislikes(package_or_order)
    package_or_order.archived_exclusions
  end

  def box_extra_line_items(package_or_order)
    package_or_order.extras_description
  end

  def price(package_or_order)
    package_or_order.price
  end

  def bucky_box_transaction_fee(package_or_order)
    package_or_order.archived_consumer_delivery_fee
  end

  def total_price(package_or_order)
    package_or_order.total_price
  end

  def customer_email(customer)
    customer.email
  end

  def customer_special_preferences(customer)
    customer.special_order_preference
  end

  def package_status(package)
    package.status
  end

  def delivery_status(delivery)
    delivery.status
  end
end
