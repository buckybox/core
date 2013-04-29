class CsvExport
  def initialize(args)
    @distributor = args[:distributor]
    @ids         = args[:ids]
    @date        = args[:date]
    @screen      = args[:screen]
  end

  def csv
    [ data, file_args ]
  end

protected

  attr_reader :distributor
  attr_reader :ids
  attr_reader :date
  attr_reader :screen
  attr_reader :sorter
  attr_reader :generator

  def file_args
    { type: file_type, filename: file_name }
  end

  def file_name
    "bucky-box-#{screen}-export-#{date}.csv"
  end

  def file_type
    'text/csv; charset=utf-8; header=present'
  end

  def data
    generate_csv_output(csv_data) if csv_data
  end

  def generate_csv_output(csv_data, csv_generator)
    csv = csv_generator.new(csv_data)
    csv.generate
  end

  def sorted_and_grouped(items, sorter = DeliverySort)
    sorter.grouped_by_boxes(items).flat_map { |box, array| array }
  end

  def sorted_by_dso(items, sorter = DeliverySort)
    sorter.by_dso(items, date)
  end
end
