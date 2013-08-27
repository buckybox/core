class Distributor::WelcomeController < Distributor::BaseController

  def index
    distributor_setup = Distributor::Setup.new(current_distributor)

    if distributor_setup.done?
      redirect_to distributor_customers_url
    else
      flash[:info] = "Please start by creating a Route."
      redirect_to distributor_settings_routes_url(show_welcome: true)
    end
  end

end
