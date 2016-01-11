class Distributor::BillingController < Distributor::BaseController
  def show
    last_invoices = current_distributor.invoices.order('distributor_invoices.to').last(5).reverse
    current_pricing = current_distributor.pricing
    other_pricings = Distributor::Pricing.plans_for_currency(current_pricing.currency).reject do |pricing|
      pricing == current_pricing
    end

    render locals: {
      current_pricing: current_pricing,
      other_pricings: other_pricings,
      invoices: last_invoices,
    }
  end
end
