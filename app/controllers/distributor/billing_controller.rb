class Distributor::BillingController < Distributor::BaseController
  def show
    last_invoices = current_distributor.invoices.order('distributor_invoices.to').last(5).reverse

    render locals: {
      pricing: current_distributor.pricing,
      invoices: last_invoices,
    }
  end
end
