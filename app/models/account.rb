class Account < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :customer

  has_many :orders
  has_many :payments
  has_many :transactions

  composed_of :balance,
    :class_name => "Money",
    :mapping => [%w(balance_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :distributor, :customer, :balance

  validates_presence_of :distributor, :customer, :balance
end
