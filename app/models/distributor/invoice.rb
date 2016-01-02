class Distributor::Invoice < ActiveRecord::Base
  attr_accessible :distributor, :from, :to, :description, :amount, :currency

  belongs_to :distributor

  monetize :amount_cents

  def date
    to
  end

  def read_only?
    true
  end

  def self.create_invoice!(distributor)
    pricing = distributor.pricing

    from = pricing.last_billing_date + 1.day
    to = from + 1.month - 1.day

    usage = pricing.usage_between(from, to)
    due = [usage - pricing.account_balance, CrazyMoney.zero].max

    create!(
      distributor: distributor,
      from: from,
      to: to,
      amount: due,
      description: pricing.description,
      currency: pricing.currency,
    )
  end

end
