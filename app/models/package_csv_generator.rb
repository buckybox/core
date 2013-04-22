class PackageCsvGenerator < CsvGenerator
protected

  def get_order(export_item)
    export_item.order
  end

  def get_package(export_item)
    export_item
  end

  def get_delivery(export_item)
    export_item.deliveries.ordered.first
  end
end
