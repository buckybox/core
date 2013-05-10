module SalesCsv
  class OrderExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, OrderGenerator)
      super(args)
    end

  private

    def list
      @list ||= ( packing_screen? ? distributor.packing_list_by_date(date) : distributor.delivery_list_by_date(date) )
    end

    def items
      @orders ||= ( packing_screen? ? list.ordered_packages(ids) : list.ordered_deliveries(ids) )
    end
  end
end
