class PackageCsvExport < CsvExport
  def initialize(args)
    @generator = args.fetch(:generator, PackageCsvGenerator)
    super(args)
  end

private

  def items
    @packages ||= distributor.packages_with_ids(ids)
  end
end
