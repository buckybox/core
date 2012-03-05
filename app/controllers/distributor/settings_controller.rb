class Distributor::SettingsController < Distributor::BaseController
  respond_to :html, :json

  def routes
    @route = Route.new
    @routes = current_distributor.routes
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def business_info
  end

  def bank_info
    @bank_information = current_distributor.bank_information || BankInformation.new
  end

  def invoicing_info
    @invoice_information = current_distributor.invoice_information || InvoiceInformation.new
  end

  def reporting
  end
end
