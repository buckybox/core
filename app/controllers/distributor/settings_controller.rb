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
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def contact_info
  end

  def bank_info
    @invoice_information = current_distributor.invoice_information || InvoiceInformation.new
  end

  def reporting
  end
end
