class PackageCsvGenerator < CsvGenerator
  def initialize(data, options = {})
    @row_generator = options.fetch(:row_generator, PackageCsvRowGenerator)
    super(data)
  end
end
