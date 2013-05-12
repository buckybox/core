module SalesCsv
  class PackageExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, PackageGenerator)
      super(args)
    end

  private

    def list
      @list ||= distributor.packing_list_by_date(date)
    end

    def items
      @packages ||= list.ordered_packages(ids)
    end
  end
end
