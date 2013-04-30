class DeliveryCsvGenerator < CsvGenerator
  def initialize(data, options = {})
    @row_generator = options.fetch(:row_generator, DeliveryCsvRowGenerator)
    super(data)
  end
end
