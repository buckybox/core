class Api::V0::DeliveryServicesController < Api::V0::BaseController
  api :GET, '/delivery_services',  "Get list of delivery services"
  example "v0/delivery_services"
  def index
    @delivery_services = @distributor.delivery_services
  end

  api :GET, '/delivery_services/:id', "Returns single delivery service"
  example "v0/delivery_services/123"
  def show
    delivery_service_id = params[:id]
    @delivery_service = @distributor.delivery_services.find_by(id: delivery_service_id)
  end
end
