class Distributor::BoxesController < Distributor::BaseController
  respond_to :json

  def show
    box = current_distributor.boxes.find(params[:id])

    respond_with box
  end
end

