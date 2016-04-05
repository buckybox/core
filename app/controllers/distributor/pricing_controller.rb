class Distributor::PricingController < Distributor::BaseController
  def update
    name = params.fetch(:link_action)

    current_pricing = current_distributor.pricing

    pricing = current_pricing.pricings_for_currency.detect { |p| p.name == name }
    pricing.discount_percentage = current_pricing.discount_percentage
    pricing.invoicing_day_of_the_month = current_pricing.invoicing_day_of_the_month
    pricing.distributor = current_distributor
    pricing.save!

    redirect_to distributor_billing_path
  end
end
