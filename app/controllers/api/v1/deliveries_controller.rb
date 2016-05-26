class Api::V1::DeliveriesController < Api::V1::BaseController
  def index
    export = Distributor::Export::Utils.get_export(@distributor, params)
    csv_string = export.csv.first
    csv_array = CSV.parse(csv_string)

    render json: csv_array
  end

  def yellow_zone
    render json: {
      window_start_from: @distributor.window_start_from,
      window_end_at: @distributor.window_end_at,
    }
  end
end
