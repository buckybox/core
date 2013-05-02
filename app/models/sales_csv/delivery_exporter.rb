module SalesCsv
  class DeliveryExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, DeliveryGenerator)
      super(args)
    end

  private

    def items
      @deliveries ||= distributor.deliveries_with_ids(ids)
    end
  end
end
