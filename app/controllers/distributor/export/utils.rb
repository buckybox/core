module Distributor::Export::Utils
module_function

  def determine_type(args)
    [:deliveries, :packages, :orders].find { |key| args.key?(key) }
  end

  def build_csv_exporter_constant(type)
    type_constant = type.to_s.singularize.titleize.constantize
    "SalesCsv::#{type_constant}Exporter".constantize
  end

  def build_csv_args(type, args)
    {
      distributor:  args[:distributor],
      ids:          args[type],
      date:         Date.parse(args[:date]),
      screen:       args[:screen],
    }
  end

  def build_csv(type, args)
    csv_exporter = build_csv_exporter_constant(type)
    csv_args     = build_csv_args(type, args)
    csv_exporter.new(csv_args)
  end

  def get_export(distributor, args)
    args.merge!(distributor: distributor)
    found_type = determine_type(args)
    build_csv(found_type, args) if found_type
  end
end
