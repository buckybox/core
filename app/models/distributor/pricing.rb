class Distributor::Pricing < ActiveRecord::Base
  attr_accessible :name, :flat_fee, :percentage_fee, :percentage_fee_max, :discount_percentage, :currency

  belongs_to :distributor

  monetize :flat_fee_cents
  monetize :percentage_fee_max_cents

  def description
    parts = []

    unless percentage_fee.zero?
      parts << "#{percentage_fee}% capped at #{percentage_fee_max.with_currency(currency)} #{currency} per delivery"
    end

    unless flat_fee.zero?
      parts << "#{flat_fee.with_currency(currency)} #{currency} monthly"
    end

    parts.join(" + ")
  end

  def self.default_for_currency(currency)
    default_pricings = {
      "USD" => { flat_fee:  70, percentage_fee_max: 0.20 },
      "NZD" => { flat_fee: 100, percentage_fee_max: 0.30 },
      "AUD" => { flat_fee:  95, percentage_fee_max: 0.30 },
      "CAD" => { flat_fee:  95, percentage_fee_max: 0.30 },
      "EUR" => { flat_fee:  60, percentage_fee_max: 0.20 },
      "GBP" => { flat_fee:  45, percentage_fee_max: 0.15 },
    }.freeze

    pricing = default_pricings.fetch(currency, default_pricings.fetch("USD"))

    pricing.merge!(
      percentage_fee: 0.5,
      name: "Standard",
      currency: currency,
    )

    new(pricing)
  end
end
