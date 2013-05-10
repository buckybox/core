module SalesCsv
  class DeliveryExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, DeliveryGenerator)
      super(args)
    end

  private

    def list
      @list ||= distributor.delivery_list_by_date(date)
    end

    def items
      @deliveries ||= list.ordered_deliveries(ids)
    end
  end
end
