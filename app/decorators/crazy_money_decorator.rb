require "draper"

class CrazyMoneyDecorator < Draper::Decorator
  delegate_all

  def with_currency
    distributor = context[:distributor]
    currency = distributor.try(:currency)
    object.with_currency(currency)
  end

  def to_human
    if self < 1E3
      amount, suffix = self, ""
    else
      amount, suffix = (self / 1E3), "k"
    end

    [
      amount.round.to_s(decimal_places: 0),
      suffix,
    ].join
  end
end
