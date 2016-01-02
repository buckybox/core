class Distributor::Invoice < ActiveRecord::Base
  attr_accessible :distributor, :from, :to, :description, :amount, :currency

  belongs_to :distributor

  monetize :amount_cents

  def self.create_invoice!(distributor)
    distributor.use_local_time_zone do
      pricing = distributor.pricing

      from = pricing.last_invoiced_date
      to = from + 1.month - 1.day

      return if to >= Date.current

      usage = pricing.usage_between(from, to)
      due = [usage - pricing.account_balance, CrazyMoney.zero].max
      description = "#{pricing.name} plan: #{pricing.description}"

      create!(
        distributor: distributor,
        from: from,
        to: to,
        amount: due,
        description: description,
        currency: pricing.currency,
      )
    end
  end
end
