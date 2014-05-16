class Distributor::Settings::Payments::Paypal < Distributor::Settings::Payments::Base
  delegate :payment_paypal, to: :distributor

  def distributor_email
    distributor.email
  end

  def initialize(args)
    super
    @paypal = args[:paypal]
  end

  def save
    payment_paypal = @paypal[:payment_paypal].to_bool
    updated = distributor.update_attributes(payment_paypal: payment_paypal)
    return unless updated
    return true unless payment_paypal

    paypal_omni = OmniImporter.paypal.find_by(country_id: distributor.country.id) || OmniImporter.generic_paypal
    new_omni_importers = distributor.omni_importers | [paypal_omni]
    distributor.omni_importers = new_omni_importers
    distributor.save
  end

  def errors
    distributor.errors.values.flatten
  end
end

