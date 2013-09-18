require "draper"

class DeliveryServiceDecorator < Draper::Decorator
  delegate_all

  def fee
    object.fee.with_currency(distributor.currency)
  end
end

