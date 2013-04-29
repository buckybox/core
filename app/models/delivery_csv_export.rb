class DeliveryCsvExport < CsvExport
private

  def csv_data
    @csv_data ||= sorted_by_dso(deliveries)
  end

  def generate_csv_output(csv_data, csv_generator = DeliveryCsvGenerator)
    super(csv_data, csv_generator)
  end

  def deliveries
    @deliveries ||= distributor.deliveries_with_ids(ids)
  end
end
