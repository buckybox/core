class Distributor::WizardController < Distributor::BaseController
  def business
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def routes
    @route = Route.new
    @routes = current_distributor.routes
  end

  def payment
    @bank = Bank.new
  end

  def billing
    @invoice_information = InvoiceInformation.new
  end

  def success
  end
end
