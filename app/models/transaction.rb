class Transaction < ActiveRecord::Base
  belongs_to :account
  belongs_to :transactionable, polymorphic: true

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  TRANSACTIONABLE_TYPE = %w(Delivery Payment Account)

  attr_accessible :account, :transactionable, :amount, :description

  validates_presence_of :account_id, :transactionable_id, :transactionable_type, :amount, :description
  validates :transactionable_type, inclusion: { in: TRANSACTIONABLE_TYPE, message: "%{value} is not a valid kind of transaction type." }

  default_scope order('created_at DESC')

  def reverse_transaction!
    account.reverse_transaction!(amount, description)
  end
end
