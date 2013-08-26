class Distributor::WizardController < Distributor::BaseController
  def business
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def delivery_services
    @delivery_service = DeliveryService.new
    @delivery_services = current_distributor.delivery_services
  end

  def payment
    @bank_information = BankInformation.new
  end

  def billing
    @invoice_information = InvoiceInformation.new
  end

  def success
  end
end
