class Distributor::DeliveryServicesController < Distributor::ResourceController
  actions :all, except: [:index, :destroy]

  respond_to :html, :xml, :json

  def create
    create! { distributor_settings_delivery_services_url }
    tracking.event(current_distributor, 'distributor_created_delivery_service')
  end

  def update
    update! { distributor_settings_delivery_services_url }
  end
end
