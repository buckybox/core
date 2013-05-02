module SalesCsv
  class OrderGenerator < Generator
    def initialize(data, options = {})
      @row_generator = options.fetch(:row_generator, OrderRowGenerator)
      super(data)
    end
  end
end
