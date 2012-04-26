class Extra < ActiveRecord::Base

  belongs_to :distributor

  validates_presence_of :distributor, :name, :unit, :price

  attr_accessible :distributor, :name, :unit, :price
  scope :alphabetically, order('name ASC, unit ASC')

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  def to_hash
    {name: name, unit: unit, price_cents: price_cents, currency: currency}
  end

  def name_with_unit
    "#{name} (#{unit})"
  end

  def name_with_price(customer_discount)
    "#{name} - #{price_with_discount(customer_discount).format} (#{unit})"
  end

  def price_with_discount(customer_discount)
    Package.calculated_extras_price([self.to_hash.merge(count: 1)], customer_discount)
  end

  FUZZY_MATCH_THRESHOLD = 0.80
  def match_import_extra?(extra)
    Bucky::Util.fuzzy_match(name, extra.name) > FUZZY_MATCH_THRESHOLD &&
      (extra.unit.blank? || Bucky::Util.fuzzy_match(extra.unit.gsub(/ +/,''), extra.unit.gsub(/ +/,'')))
  end

  def fuzzy_match(extra)
    return 0 if extra.blank?
    match = 1.0
    name_match = Bucky::Util.fuzzy_match(name, extra.name)
    match *= name_match
    if extra.unit.blank?
      match *= 1.0 # If the unit was missed, assume to match any unit
    else
      unit_match = Bucky::Util.fuzzy_match(unit.gsub(/ +/,''), extra.unit.gsub(/ +/,'')) # Ignore extra and missing spaces ' '
      match *= (0.9+(unit_match*0.1)) # Reduce impact of a poor unit match
    end
    match
  end
end
