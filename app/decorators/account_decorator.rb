require "draper"

class AccountDecorator < Draper::Decorator
  delegate_all

  def balance
    object.balance.with_currency(object.distributor.currency)
  end
end

