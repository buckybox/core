class Deduction < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :account, autosave: true
  belongs_to :deductable, polymorphic: true

  has_one :customer, through: :account

  belongs_to :transaction
  belongs_to :reversal_transaction, class_name: 'Transaction'
  has_many :transactions, as: :transactionable

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :account_id, :amount, :kind, :description, :distributor, :source,
    :deductable, :deductable_id, :deductable_type

  KINDS = %w(delivery unspecified)
  SOURCES = %W(manual delivery)

  validates_presence_of :distributor_id, :account_id, :amount, :kind, :description, :deductable_id, :deductable_type
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid kind of payment"
  validates_inclusion_of :source, in: SOURCES, message: "%{value} is not a valid source of payment"
  validates_numericality_of :amount

  before_create :make_deduction!

  default_value_for :reversed, false
  default_value_for :kind,     'unspecified'
  default_value_for :source,   'manual'

  def reverse_deduction!
    raise "This deduction has already been reversed." if self.reversal_transaction.present?

    self.reversed = true
    self.reversed_at = Time.current

    options = { kind: 'amend', description: "REVERSED " + self.transaction.description }
    self.reversal_transaction = self.account.add_to_balance(self.amount, options)

    self.save

    return self.reversal_transaction
  end

  private

  def make_deduction!
    raise "This deduction has already been applied!" if self.transaction.present?

    self.transaction = account.subtract_from_balance(
      amount,
      transactionable: self,
      description: "Made a deduction by #{kind.humanize.downcase}.",
      display_date: Date.current
    )

    self.save

    return self.transaction
  end
end
