class Distributor::Export::DeliveriesController < Distributor::BaseController

  def index
    export = get_export(params)

    if export
      screen = params[:screen] # delivery or packing
      tracking.event(current_distributor, "export_#{screen}_list") unless current_admin.present?

      send_data(*export.csv)
    else
      redirect_to :back
    end
  end

private

  #NOTE: These methods are used to clean up the export input. When the UI gets better we should be able to remove
  # most if not all of the code.
  def get_export(args)
    found_key = find_key(args)
    csv_exporter, ids = make_sales_args(found_key, args[found_key]) if found_key
    export_args = { distributor: current_distributor, ids: ids, date: Date.parse(args[:date]), screen: args[:screen] }
    csv_exporter.new(export_args) if csv_exporter
  end

  def make_sales_args(key, value)
    key = "SalesCsv::#{key.to_s.singularize.titleize.constantize}Exporter"
    key = key.constantize
    [ key, value ]
  end

  def find_key(args)
    found_key = nil
    [:deliveries, :packages, :orders].each { |key| found_key = key if args.key?(key) }
    found_key
  end

end
