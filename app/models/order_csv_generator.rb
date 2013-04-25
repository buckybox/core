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

  def package_number(package)
    nil
  end

  def delivery_date(package)
    nil
  end

  def box_contents_short_description(package_or_order)
    box_name          = package_or_order.box.name
    has_exclusions    = !package_or_order.exclusions.empty?
    has_substitutions = !package_or_order.substitutions.empty?
    Order.short_code(box_name, has_exclusions, has_substitutions)
  end

  def box_type(package_or_order)
    package_or_order.box.name
  end

  def box_likes(package_or_order)
    package_or_order.substitutions_string
  end

  def box_dislikes(package_or_order)
    package_or_order.exclusions_string
  end

  def box_extra_line_items(package_or_order)
    Order.extras_description(package_or_order.order_extras)
  end

  def bucky_box_transaction_fee(package_or_order)
    package_or_order.consumer_delivery_fee
  end

  def package_status(package)
    nil
  end

  def delivery_status(delivery)
    nil
  end
end
