class Distributor::Pricing < ActiveRecord::Base
  attr_accessible :name, :flat_fee, :percentage_fee, :percentage_fee_max, :discount_percentage, :currency, :invoicing_day_of_the_month

  belongs_to :distributor

  monetize :flat_fee_cents
  monetize :percentage_fee_max_cents

  def usage_between(from, to)
    raise ArgumentError unless from.is_a?(Date) && to.is_a?(Date)

    deductions = distributor.deductions \
                            .where("created_at >= ? AND created_at <= ?", from, to) \
                            .where(deductable_type: "Delivery")

    cut = deductions.sum do |deduction|
      raise "currency mismatch" if deduction.distributor.currency != currency

      [deduction.amount * percentage_fee / 100, percentage_fee_max].min
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

      date = Date.new(yesterday.year, yesterday.month, invoicing_day_of_the_month - 1)
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

  def pricings_for_currency
    self.class.pricings_for_currency(currency)
  end

  def self.default_pricing_for_currency(currency)
    pricings_for_currency(currency).detect { |p| p.name == "Standard" }
  end

  def self.pricings_for_currency(currency)
    pricings = {
      "USD" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.40 },
        "Standard"  => { flat_fee:  70, percentage_fee: 0.5, percentage_fee_max: 0.20 },
        "Unlimited" => { flat_fee: 275, percentage_fee: 0.0, percentage_fee_max: 0.00 },
      },
      "NZD" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee: 100, percentage_fee: 0.5, percentage_fee_max: 0.30 },
        "Unlimited" => { flat_fee: 400, percentage_fee: 0.0, percentage_fee_max: 0.00 },
      },
      "AUD" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee:  95, percentage_fee: 0.5, percentage_fee_max: 0.30 },
        "Unlimited" => { flat_fee: 375, percentage_fee: 0.0, percentage_fee_max: 0.00 },
      },
      "CAD" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.55 },
        "Standard"  => { flat_fee:  95, percentage_fee: 0.5, percentage_fee_max: 0.30 },
        "Unlimited" => { flat_fee: 375, percentage_fee: 0.0, percentage_fee_max: 0.00 },
      },
      "EUR" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.35 },
        "Standard"  => { flat_fee:  60, percentage_fee: 0.5, percentage_fee_max: 0.20 },
        "Unlimited" => { flat_fee: 250, percentage_fee: 0.0, percentage_fee_max: 0.00 },
      },
      "GBP" => {
        "Casual"    => { flat_fee:   0, percentage_fee: 1.5, percentage_fee_max: 0.25 },
        "Standard"  => { flat_fee:  45, percentage_fee: 0.5, percentage_fee_max: 0.15 },
        "Unlimited" => { flat_fee: 175, percentage_fee: 0.0, percentage_fee_max: 0.00 },
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
