class Distributor::BillingController < Distributor::BaseController
  def show
    last_invoices = current_distributor.invoices.order('distributor_invoices.to').last(5).reverse
    current_pricing = current_distributor.pricing
    next_pricing = Distributor::Pricing.where(distributor_id: current_distributor.id).last
    other_pricings = current_pricing.pricings_for_currency.reject do |pricing|
      (next_pricing && next_pricing == pricing) || (!next_pricing && current_pricing == pricing)
    end

    render locals: {
      current_pricing: current_pricing,
      next_pricing: next_pricing,
      other_pricings: other_pricings,
      invoices: last_invoices,
    }
  end
end
