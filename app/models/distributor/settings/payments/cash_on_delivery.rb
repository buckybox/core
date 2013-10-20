class Distributor::Settings::Payments::CashOnDelivery < Distributor::Settings::Payments::Base
  delegate :payment_cash_on_delivery, to: :distributor
  delegate :cod_payment_message, to: :bank_information

  def initialize(args)
    super
    @cash_on_delivery = args[:cash_on_delivery]
  end

  def save
    @bank_information.distributor.update_attributes(
      payment_cash_on_delivery: @cash_on_delivery.delete(:payment_cash_on_delivery)
    ) && @bank_information.update_attributes(@cash_on_delivery)
  end
end
