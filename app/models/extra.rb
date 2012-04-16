class Extra < ActiveRecord::Base

  belongs_to :distributor

  validates_presence_of :distributor, :name, :unit, :price

  attr_accessible :distributor, :name, :unit, :price

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  def to_hash
    {name: name, unit: unit, price_cents: price_cents, currency: currency}
  end

  def name_with_unit
    "#{name} [#{unit}]"
  end

  def name_with_price(customer_discount)
    "#{name} - #{price_with_discount(customer_discount).format} / #{unit}"
  end

  def price_with_discount(customer_discount)
    Package.calculated_extras_price([self.to_hash.merge(count: 1)], customer_discount)
  end
end
