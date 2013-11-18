class Api::V0::DeliveryServicesController < Api::V0::BaseController
  api :GET, '/delivery_services',  "Get list of delivery services"
  example "v0/delivery_services"
  def index
    @delivery_services = @distributor.delivery_services
  end
end
