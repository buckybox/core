class Distributor::SettingsController < Distributor::BaseController
  respond_to :html, :json

  def business_info
    time = Time.new
    @default_delivery_time  = Time.new(time.year, time.month, time.day, 18)
    @default_delivery_days  = 3
    @default_automatic_time = Time.new(time.year, time.month, time.day, 18)
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def routes
    @route = Route.new
    @routes = current_distributor.routes
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
