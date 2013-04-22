class OrderCsvExport < CsvExport
  def csv_data
    @csv_data ||= orders
  end

  def calculate_date
    @calculate_date ||= Date.today
  end

  def generate_csv_output(csv_data, csv_generator = OrderCsvGenerator)
    super(csv_data, csv_generator)
  end

private

  def orders
    @orders ||= distributor.orders.where(id: ids)
  end
end
