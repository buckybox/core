class Payment < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :account
  belongs_to :bank_statement

  belongs_to :transaction
  belongs_to :reversal_transaction, :class_name => 'Transaction'

  has_one :customer, :through => :account

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :account_id, :amount, :kind, :description, :distributor, :bank_statement, :reference, :source, :payment_date

  KINDS = %w(bank_transfer credit_card unspecified)
  SOURCES = %W(manual import)

  validates_presence_of :distributor_id, :account_id, :amount, :kind, :description, :payment_date
  validates_inclusion_of :kind, :in => KINDS, :message => "%{value} is not a valid kind of payment"
  validates_inclusion_of :source, :in => SOURCES, :message => "%{value} is not a valid source of payment"
  validates_numericality_of :amount

  after_create :update_account
  before_validation :set_payment_date

  scope :bank_transfer, where(:kind => 'bank_transfer')
  scope :credit_card, where(:kind => 'credit_card')
  scope :unspecified, where(:kind => 'unspecified')

  scope :manual, where(:source => 'manual')
  scope :import, where(:source => 'import')

  scope :reversed, where(reversed: true)

  default_value_for :reversed, false
  default_value_for :kind, 'unspecified'
  default_value_for :source, 'manual'

  def update_account
    self.transaction = account.add_to_balance(amount, kind: 'payment', description: "[ID##{id}] Recieved a payment by #{source.humanize.downcase}.", display_date: payment_date)
    account.save
    save
  end

  def reverse_payment!
    raise "This payment has already been reversed!" if self.reversal_transaction.present?

    self.reversed = true
    self.reversed_at = Time.zone.now
    self.reversal_transaction = transaction.reverse_transaction!
    self.save!

    return self.reversal_transaction
  end

  private

  def set_payment_date
    self.payment_date = Time.zone.now.to_date if self.payment_date.nil?
  end
end
