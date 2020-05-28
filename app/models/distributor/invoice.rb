class Distributor::Invoice < ActiveRecord::Base
  attr_accessible :distributor, :from, :to, :description, :amount, :currency

  belongs_to :distributor

  monetize :amount_cents

  def self.create_invoice!(distributor)
    distributor.use_local_time_zone do
      pricings = Distributor::Pricing.where(distributor_id: distributor.id)
      pricing = pricings.last
      (pricings - [pricing]).each(&:delete)

      from = pricing.last_invoiced_date
      to = from + 1.month - 1.day

      return if to >= Date.current

      usage = pricing.usage_between(from, to)
      description = "#{pricing.name} plan: #{pricing.description}"

      unless pricing.discount_percentage.zero?
        description << " - #{pricing.discount_percentage}% discount"
      end

      create!(
        distributor: distributor,
        from: from,
        to: to,
        amount: usage,
        description: description,
        currency: pricing.currency,
      )
    end
  end

  def reference
    "B#{distributor.id}B#{number}X"
  end
end
