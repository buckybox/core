class Distributor::Export::DeliveriesController < Distributor::BaseController
  def index
    export = Distributor::Export::Utils.get_export(current_distributor, params)

    if export
      screen = params[:screen] # delivery or packing
      current_distributor.track("export_#{screen}_list") unless current_admin.present?

      send_data(*export.csv)
    else
      redirect_to :back
    end
  end
end
