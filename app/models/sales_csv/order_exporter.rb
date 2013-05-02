module SalesCsv
  class OrderExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, OrderGenerator)
      super(args)
    end

  private

    def items
      @orders ||= distributor.orders_with_ids(ids)
    end
  end
end
