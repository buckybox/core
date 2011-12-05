class Payment < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :customer
  has_one :transaction, :as => :transactionable

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :distributor, :customer, :amount, :kind, :description
  
  validates_presence_of :distributor, :customer, :amount, :kind, :description
end
