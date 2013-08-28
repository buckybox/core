class Distributor::WelcomeController < Distributor::BaseController

  def index
    if distributor_setup.done?
      redirect_to distributor_customers_url
    else
      flash[:info] = "Please start by creating a delivery service."
      redirect_to distributor_settings_delivery_services_url
    end
  end

end
