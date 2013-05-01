class SalesCsv::DeliveryGenerator < SalesCsv::Generator
  def initialize(data, options = {})
    @row_generator = options.fetch(:row_generator, DeliveryRowGenerator)
    super(data)
  end
end
