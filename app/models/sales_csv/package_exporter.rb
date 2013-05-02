module SalesCsv
  class PackageExporter < Exporter
    def initialize(args)
      @generator = args.fetch(:generator, PackageGenerator)
      super(args)
    end

  private

    def items
      @packages ||= distributor.packages_with_ids(ids)
    end
  end
end
