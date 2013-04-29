class OrderCsvExport < CsvExport
private

  def csv_data
    @csv_data ||= ( packing_screen? ? sorted_and_grouped(orders) : sorted_by_dso(orders) )
  end

  def generate_csv_output(csv_data, csv_generator = OrderCsvGenerator)
    super(csv_data, csv_generator)
  end

  def orders
    @orders ||= distributor.orders_with_ids(ids)
  end

  def packing_screen?
    screen == 'packing'
  end
end
