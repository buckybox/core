class Api::V1::DeliveryServicesController < Api::V1::BaseController
  api :GET, '/delivery_services', "Get list of delivery services"
  example "v1/delivery_services"
  def index
    @delivery_services = @distributor.delivery_services
  end

  api :GET, '/delivery_services/:id', "Returns single delivery service"
  example "v1/delivery_services/123"
  def show
    @delivery_service = @distributor.delivery_services.find_by(id: params[:id])
    return not_found if @delivery_service.nil?
  end
end
