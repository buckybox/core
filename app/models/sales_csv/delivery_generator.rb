module SalesCsv
  class DeliveryGenerator < Generator
    def initialize(data, options = {})
      @row_generator = options.fetch(:row_generator, DeliveryRowGenerator)
      super(data)
    end
  end
end
