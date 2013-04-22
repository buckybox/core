class OrderCsvGenerator < CsvGenerator
protected

  def get_order(export_item)
    export_item
  end

  def get_package(export_item)
    nil
  end

  def get_delivery(export_item)
    nil
  end

  def delivery_sequence_number(delivery)
    nil
  end

  #NOTE: Keeping this due to legacy CSV convention but nothing in system for it yet
  def delivery_pickup_point_name(delivery)
    nil
  end

  def package_number(package)
    nil
  end

  def delivery_date(package)
    nil
  end

  def customer_phone(package)
    nil
  end

  def delivery_address_line_1(package)
    nil
  end

  def delivery_address_line_2(package)
    nil
  end

  def delivery_address_suburb(package)
    nil
  end

  def delivery_address_city(package)
    nil
  end

  def delivery_address_postcode(package)
    nil
  end

  def delivery_note(package)
    nil
  end

  def box_contents_short_description(package)
    nil
  end

  def box_type(package)
    nil
  end

  def box_likes(package)
    nil
  end

  def box_dislikes(package)
    nil
  end

  def box_extra_line_items(package)
    nil
  end

  def price(package)
    nil
  end

  def bucky_box_transaction_fee(package)
    nil
  end

  def total_price(package)
    nil
  end
end
