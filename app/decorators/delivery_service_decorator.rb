require "draper"

class DeliveryServiceDecorator < Draper::Decorator
  delegate_all

  def formatted_fee
    object.fee.zero? ? "Free" : fee_with_currency
  end

  def fee_with_currency
    object.fee.with_currency(object.distributor.currency)
  end

  def delivery_days
    object.schedule_rule.days.map(&:capitalize).join(", ")
  end
end
