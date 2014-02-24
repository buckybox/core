require "draper"

class CrazyMoneyDecorator < Draper::Decorator
  delegate_all

  def with_currency
    distributor = context[:distributor]
    currency = distributor.try(:currency)
    object.with_currency(currency)
  end
end

