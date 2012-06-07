class Transaction < ActiveRecord::Base
  belongs_to :account

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :kind, :amount, :description, :display_date

  KINDS = %w(delivery payment amend)

  validates_presence_of :account_id, :kind, :amount, :description, :display_date
  validates :kind, inclusion: { in: KINDS, message: "%{value} is not a valid kind of transaction" }

  before_validation :set_display_date

  default_scope order('display_date DESC')

  def reverse_transaction!
    account.reverse_transaction!(amount, description)
  end

  private

  def set_display_date
    self.display_date = Time.zone.now.to_date if self.display_date.nil?
  end
end
