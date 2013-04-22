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
      'Price', 'Bucky Box Transaction Fee', 'Total Price', 'Customer Email', 'Customer Special Preferences'
    ]
  end

protected

  def generate_row(export_item)
    order, package, delivery, customer = seperate_data_row(export_item)

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
      customer_phone(package),
      new_customer(customer),
      delivery_address_line_1(package),
      delivery_address_line_2(package),
      delivery_address_suburb(package),
      delivery_address_city(package),
      delivery_address_postcode(package),
      delivery_note(package),
      box_contents_short_description(package),
      box_type(package),
      box_likes(package),
      box_dislikes(package),
      box_extra_line_items(package),
      price(package),
      bucky_box_transaction_fee(package),
      total_price(package),
      customer_email(customer),
      customer_special_preferences(customer)
    ]
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

  def customer_phone(package)
    package.address.phone_1
  end

  def new_customer(customer)
    customer.new? ? 'NEW' : nil
  end

  def delivery_address_line_1(package)
    package.archived_address_details.address_1
  end

  def delivery_address_line_2(package)
    package.archived_address_details.address_2
  end

  def delivery_address_suburb(package)
    package.archived_address_details.suburb
  end

  def delivery_address_city(package)
    package.archived_address_details.city
  end

  def delivery_address_postcode(package)
    package.archived_address_details.postcode
  end

  def delivery_note(package)
    package.archived_address_details.delivery_note
  end

  def box_contents_short_description(package)
    package.string_sort_code
  end

  def box_type(package)
    package.archived_box_name
  end

  def box_likes(package)
    package.archived_substitutions
  end

  def box_dislikes(package)
    package.archived_exclusions
  end

  def box_extra_line_items(package)
    package.extras_description
  end

  def price(package)
    package.price
  end

  def bucky_box_transaction_fee(package)
    package.archived_consumer_delivery_fee
  end

  def total_price(package)
    package.total_price
  end

  def customer_email(customer)
    customer.email
  end

  def customer_special_preferences(customer)
    customer.special_order_preference
  end
end
