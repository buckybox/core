class OrderCsvExport < CsvExport
  def initialize(args)
    @generator = args.fetch(:generator, OrderCsvGenerator)
    super(args)
  end

private

  def items
    @orders ||= distributor.orders_with_ids(ids)
  end
end
