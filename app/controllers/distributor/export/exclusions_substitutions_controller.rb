class Distributor::Export::ExclusionsSubstitutionsController < Distributor::BaseController

  def index
    date = Date.parse(params[:date])
    key = Distributor::Export::Utils.determine_type(params)
    packages_or_orders = current_distributor.public_send(key).where(id: params[key])
    csv_string = ExclusionsSubstitutionsCsv.generate(date, packages_or_orders)

    send_csv("bucky-box-excludes-substitutes-export-#{date.iso8601}", csv_string)
  end

end
