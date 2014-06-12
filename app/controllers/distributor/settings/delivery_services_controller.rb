class Distributor::Settings::DeliveryServicesController < Distributor::BaseController
  def show
    render_form
  end

  def create
    delivery_service_params = params[:delivery_service]

    delivery_service = delivery_service.new(delivery_service_params)
    delivery_service.distributor = current_distributor

    if delivery_service.save
      flash.now[:notice] = "Your new delivery_service item has heen created."

      tracking.event(current_distributor, 'new_delivery_service')
    else
      flash.now[:error] = delivery_service.errors.full_messages.to_sentence
    end

    render_form
  end

  def update
    delivery_service_params = params[:delivery_service]
    delivery_service = current_distributor.delivery_services.find(delivery_service_params.delete(:id))

    if delivery_service.update_attributes(delivery_service_params)
      flash.now[:notice] = "Your delivery_service item has heen updated."
    else
      flash.now[:error] = delivery_service.errors.full_messages.to_sentence
    end

    render_form
  end

private

  def render_form
    delivery_services = current_distributor.delivery_services.decorate
    delivery_services.unshift(new_delivery_service) # new delivery service

    render 'distributor/settings/delivery_services', locals: {
      delivery_services: delivery_services,
    }
  end

  def new_delivery_service
    DeliveryService.new(distributor: current_distributor).decorate
  end

end
