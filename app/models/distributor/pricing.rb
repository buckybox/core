class Distributor::Pricing < ActiveRecord::Base
  attr_accessible :name, :flat_fee, :percentage_fee, :percentage_fee_max, :discount_percentage, :currency, :invoicing_day_of_the_month

  belongs_to :distributor

  monetize :flat_fee_cents
  monetize :percentage_fee_max_cents

  validates_inclusion_of :invoicing_day_of_the_month, in: 1..28

  def usage_between(from, to)
    raise ArgumentError unless from.is_a?(Date) && to.is_a?(Date)

    deductions = distributor.deductions \
                            .where("created_at >= ? AND created_at <= ?", from, to) \
                            .where(deductable_type: "Delivery")

    cut = deductions.sum do |deduction|
      amount = deduction.amount

      from = deduction.distributor.currency
      to = currency
      amount = exchange_currency(amount, from, to) if from != to

      [amount * percentage_fee / 100, percentage_fee_max].min
    end

    total = CrazyMoney.new(cut) + flat_fee

    total * ((100 - discount_percentage) / 100)
  end

  def current_usage
    distributor.use_local_time_zone do
      usage_between last_invoiced_date, Date.current
    end
  end

  def last_billed_date
    distributor.use_local_time_zone do
      last_invoice = distributor.invoices.order('distributor_invoices.to').last
      return last_invoice.to if last_invoice

      # otherwise we assume it was invoicing_day_of_the_month
      yesterday = Date.yesterday

      date = Date.new(yesterday.year, yesterday.month, invoicing_day_of_the_month) - 1.day
      date -= 1.month if yesterday.day < invoicing_day_of_the_month

      date
    end
  end

  def last_invoiced_date
    last_billed_date + 1.day
  end

  def next_invoicing_date
    last_invoiced_date + 1.month
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

  def ==(other)
    return false unless other.is_a?(self.class)

    %i(
      name
      flat_fee_cents
      percentage_fee
      percentage_fee_max_cents
      currency
    ).all? do |attr|
      other.public_send(attr) == public_send(attr)
    end
  end

  private def exchange_currency(amount, from, to)
    require 'money'
    require 'money/bank/google_currency'
    require 'monetize'

    Money.default_bank = Money::Bank::GoogleCurrency.new

    money = Monetize.parse("#{from} #{amount}")
    CrazyMoney.new(money.exchange_to(to).to_s)
  end

  def pricings_for_currency
    self.class.pricings_for_currency(currency)
  end

  def self.default_pricing_for_currency(currency)
    pricings_for_currency(currency).detect { |p| p.name == "Casual" }
  end

  def self.pricings_for_currency(currency)
    pricings = {
      "USD" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.40 },
        "Standard"  => { flat_fee: 45, percentage_fee: 0.5, percentage_fee_max: 0.20 },
      },
      "NZD" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee: 65, percentage_fee: 0.5, percentage_fee_max: 0.30 },
      },
      "AUD" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee: 65, percentage_fee: 0.5, percentage_fee_max: 0.30 },
      },
      "CAD" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee: 65, percentage_fee: 0.5, percentage_fee_max: 0.30 },
      },
      "EUR" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.35 },
        "Standard"  => { flat_fee: 40, percentage_fee: 0.5, percentage_fee_max: 0.20 },
      },
      "GBP" => {
        "Casual"    => { flat_fee:  0, percentage_fee: 1.5, percentage_fee_max: 0.25 },
        "Standard"  => { flat_fee: 35, percentage_fee: 0.5, percentage_fee_max: 0.15 },
      },
    }.freeze

    currency = pricings.key?(currency) ? currency : "USD"
    pricings = pricings.fetch(currency).dup

    pricings.map do |pricing_name, pricing_details|
      pricing_details.merge!(
        name: pricing_name,
        currency: currency,
      )

      new(pricing_details)
    end
  end
end
