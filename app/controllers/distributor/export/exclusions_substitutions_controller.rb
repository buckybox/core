class Distributor::Export::ExclusionsSubstitutionsController < Distributor::BaseController

  def index
    date = Date.parse(params[:date])
    key = find_key(params)
    packages_or_orders = current_distributor.public_send(key).where(id: params[key])
    csv_string = ExclusionsSubstitutionsCsv.generate(date, packages_or_orders)

    send_csv("bucky-box-excludes-substitutes-export-#{date.iso8601}", csv_string)
  end

private

  def find_key(args)
    found_key = nil
    [:deliveries, :packages, :orders].each { |key| found_key = key if args.key?(key) }
    found_key
  end

end
