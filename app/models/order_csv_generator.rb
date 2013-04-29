class OrderCsvGenerator < CsvGenerator
  def initialize(data)
    @row_generator = OrderCsvRowGenerator
    super(data)
  end
end
