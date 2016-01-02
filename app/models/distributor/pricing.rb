class Distributor::Pricing < ActiveRecord::Base
  attr_accessible :name, :flat_fee, :percentage_fee, :percentage_fee_max, :discount_percentage, :currency

  belongs_to :distributor

  monetize :flat_fee_cents
  monetize :percentage_fee_max_cents

  def account_balance
    CrazyMoney.zero # FIXME
  end

  def current_balance
    account_balance - current_usage
  end

  def current_usage
    delivery_cut + flat_fee
  end

  def delivery_cut
    deductions = distributor.deductions \
      .where("created_at >= ?", last_billing_date) \
      .where(deductable_type: "Delivery")

    deductions.sum do |deduction|
      [deduction.amount * percentage_fee, percentage_fee_max].min
    end
  end

  def billing_day_of_the_month
    20
  end

  def last_billing_date
    distributor.use_local_time_zone do
      yesterday = Date.yesterday

      date = Date.new(yesterday.year, yesterday.month, billing_day_of_the_month)
      date -= 1.month if yesterday.day < billing_day_of_the_month

      date
    end
  end

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
