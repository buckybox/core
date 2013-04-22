class CsvExport
  def initialize(distributor, ids)
    @distributor = distributor
    @ids = ids
  end

  def csv
    [data, file_args]
  end

protected

  attr_reader :distributor
  attr_reader :ids

  def data
    build_csv_for_export
  end

  def date
    calculate_date
  end

  def file_args
    { type: file_type, filename: file_name }
  end

  def file_name
    "bucky-box-export-#{date}.csv"
  end

  def file_type
    'text/csv; charset=utf-8; header=present'
  end

  def build_csv_for_export
    generate_csv_output(csv_data) if csv_data
  end

  def generate_csv_output(csv_data, csv_generator)
    csv = csv_generator.new(csv_data)
    csv.generate
  end
end
