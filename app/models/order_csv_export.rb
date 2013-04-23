class OrderCsvExport < CsvExport
  def csv_data
    @csv_data ||= begin
      if screen == 'packing'
        export_items = package_order
      else
        export_items = delivery_order
      end
      export_items
    end
  end

  def generate_csv_output(csv_data, csv_generator = OrderCsvGenerator)
    super(csv_data, csv_generator)
  end

private

  def orders
    @orders ||= distributor.orders.where(id: ids)
  end

  def package_order
    export_items = []
    DeliverySort.new(orders).grouped_by_boxes.each do |box, array|
      array.each { |package| export_items << package }
    end
    export_items
  end

  def delivery_order
    date_orders = []
    wday = date.wday

    date_orders = orders.includes({ account: { customer: { address:{}, deliveries: { delivery_list: {} } } }, order_extras: {}, box: {} })

    sorted_orders = date_orders.sort do |a,b|
      comp = a.dso(wday) <=> b.dso(wday)
      comp.zero? ? (b.created_at <=> a.created_at) : comp
    end
    FutureDeliveryList.new(date, sorted_orders).deliveries
  end
end
