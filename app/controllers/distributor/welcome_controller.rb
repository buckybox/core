class Distributor::WelcomeController < Distributor::BaseController

  def index
    if distributor_setup.finished_settings?
      redirect_to distributor_customers_url
    else
      redirect_to distributor_settings_delivery_services_url(welcome: true)
    end
  end

end
