class Distributor::WizardController < Distributor::BaseController
  def business
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes
  end

  def routes
  end

  def payment
  end

  def billing
  end

  def success
  end
end
