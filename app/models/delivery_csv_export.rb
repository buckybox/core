class DeliveryCsvExport < CsvExport
  def initialize(args)
    @generator = args.fetch(:generator, DeliveryCsvGenerator)
    super(args)
  end

private

  def items
    @deliveries ||= distributor.deliveries_with_ids(ids)
  end
end
