class Distributor::Export::ExtrasController < Distributor::BaseController

  def index
    date = Date.parse(params[:export_extras][:date])
    csv_string = ExtrasCsv.generate(current_distributor, date)

    send_csv("bucky-box-extra-line-items-export-#{date.iso8601}", csv_string)
  end

end
