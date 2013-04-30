class OrderCsvGenerator < CsvGenerator
  def initialize(data, options = {})
    @row_generator = options.fetch(:row_generator, OrderCsvRowGenerator)
    super(data)
  end
end
