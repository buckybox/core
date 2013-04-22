class DeliveryCsvExport < CsvExport
  def csv_data
    @csv_data ||= begin
      export_items = deliveries.ordered
      export_items.sort_by { |ei| ei.dso }
    end
  end

  def calculate_date
    @calculate_date ||= deliveries.first.delivery_list.date
  end

  def generate_csv_output(csv_data, csv_generator = DeliveryCsvGenerator)
    super(csv_data, csv_generator)
  end

private

  def deliveries
    @deliveries ||= distributor.deliveries.where(id: ids)
  end
end
