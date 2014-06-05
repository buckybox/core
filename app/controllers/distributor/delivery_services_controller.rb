class Distributor::DeliveryServicesController < Distributor::ResourceController
  actions :all, except: [:index]

  def create
    create! { distributor_settings_delivery_services_url }
    tracking.event(current_distributor, 'new_delivery_service')
  end

  def update
    update! { distributor_settings_delivery_services_url }
  end

  def destroy
    destroy! { distributor_settings_delivery_services_url }
  end
end
