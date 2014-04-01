class Distributor::Settings::Payments::Paypal < Distributor::Settings::Payments::Base
  delegate :payment_paypal, to: :distributor
  # delegate :business_email, to: :bank_information
  def business_email; "joe@paypal.com"; end

  def initialize(args)
    super
    @paypal = args[:paypal]
  end

  def save
    # @bank_information.distributor.update_attributes(
    #   payment_paypal: @paypal.delete(:payment_paypal)
    # ) && @bank_information.update_attributes(@paypal)
    true
  end
end

