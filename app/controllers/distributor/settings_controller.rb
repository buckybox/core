class Distributor::SettingsController < Distributor::BaseController

  respond_to :html, :json

  def index
    redirect_to action: :routes
  end

  def routes
    @route = Route.new
    @routes = current_distributor.routes
  end

  def boxes
  end

  def contact_info
  end

  def bank_info
  end

  def basic_reporting
  end

end
