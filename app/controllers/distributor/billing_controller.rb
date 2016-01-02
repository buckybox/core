class Distributor::BillingController < Distributor::BaseController
  def show
    render locals: { pricing: current_distributor.pricing }
  end
end
