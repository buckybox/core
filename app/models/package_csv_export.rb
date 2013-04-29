class PackageCsvExport < CsvExport
private

  def csv_data
    @csv_data ||= sorted_and_grouped(packages)
  end

  def generate_csv_output(csv_data, csv_generator = PackageCsvGenerator)
    super(csv_data, csv_generator)
  end

  def packages
    @packages ||= distributor.packages_with_ids(ids)
  end
end
