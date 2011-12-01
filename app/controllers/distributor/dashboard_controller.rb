class Distributor::DashboardController < Distributor::BaseController
  def index
    redirect_to distributor_wizard_business_path and return unless current_distributor.name?
  end
end
