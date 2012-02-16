class Transaction < ActiveRecord::Base
  belongs_to :account

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :kind, :amount, :description

  default_scope order('created_at DESC')

  KINDS = %w(delivery payment amend)

  validates_presence_of :account, :kind, :amount, :description
  validates :kind, inclusion: { in: KINDS, message: "%{value} is not a valid kind of transaction" }
end
