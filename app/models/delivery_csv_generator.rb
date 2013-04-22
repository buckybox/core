class DeliveryCsvGenerator < CsvGenerator
protected

  def get_order(export_item)
    export_item.order
  end

  def get_package(export_item)
    export_item.package
  end

  def get_delivery(export_item)
    export_item
  end
end
