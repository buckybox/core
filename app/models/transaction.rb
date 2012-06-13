class Transaction < ActiveRecord::Base
  belongs_to :account
  belongs_to :transactionable, polymorphic: true

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :transactionable, :amount, :description, :display_time

  validates_presence_of :account_id, :transactionable_id, :transactionable_type, :amount, :description, :display_time

  default_scope order('display_time DESC, created_at DESC')

  default_value_for :display_time do
    display_time = Date.current
  end
end
