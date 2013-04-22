class PackageCsvExport < CsvExport
  def csv_data
    @csv_data ||= begin
      export_items = []
      DeliverySort.new(packages).grouped_by_boxes.each do |box, array|
        array.each { |package| export_items << package }
      end
      export_items
    end
  end

  def calculate_date
    @calculate_date ||= packages.first.packing_list.date
  end

  def generate_csv_output(csv_data, csv_generator = PackageCsvGenerator)
    super(csv_data, csv_generator)
  end

private

  def packages
    @packages ||= distributor.packages.where(id: ids)
  end
end
