class Distributor::PricingController < Distributor::BaseController
  def update
    name = params.fetch(:link_action)

    pricing = current_distributor.pricing.pricings_for_currency.detect { |p| p.name == name }
    pricing.distributor = current_distributor
    pricing.save!

    redirect_to distributor_billing_path
  end
end
