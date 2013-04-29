class PackageCsvGenerator < CsvGenerator
  def initialize(data)
    @row_generator = PackageCsvRowGenerator
    super(data)
  end
end
