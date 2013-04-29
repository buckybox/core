class DeliveryCsvGenerator < CsvGenerator
  def initialize(data)
    @row_generator = DeliveryCsvRowGenerator
    super(data)
  end
end
