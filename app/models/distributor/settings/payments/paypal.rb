class Distributor::Settings::Payments::Paypal < Distributor::Settings::Payments::Base
  delegate :payment_paypal, :paypal_email, to: :distributor

  def initialize(args)
    super
    @paypal = args[:paypal]
  end

  def save
    distributor.update_attributes(@paypal) || return

    # load up PayPal omni
    paypal_omni = OmniImporter.paypal.find_by(country_id: distributor.country.id) || OmniImporter.generic_paypal
    new_omni_importers = distributor.omni_importers | [paypal_omni]
    distributor.omni_importers = new_omni_importers
    distributor.save
  end
end
