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
    distributor.update_attributes(payment_paypal: @paypal[:payment_paypal])
  end
end

