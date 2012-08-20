class Payment < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :account, autosave: true
  belongs_to :payable, polymorphic: true
  belongs_to :transaction
  belongs_to :reversal_transaction, class_name: 'Transaction'

  has_one :customer, through: :account

  has_many :transactions, as: :transactionable

  monetize :amount_cents

  attr_accessible :account, :account_id, :amount, :kind, :description, :distributor, :reference, :source,
    :display_time, :payable, :payable_id, :payable_type

  KINDS = %w(bank_transfer credit_card cash delivery unspecified)
  SOURCES = %W(manual import)

  validates_presence_of :distributor_id, :account_id, :amount, :kind, :description, :display_time, :payable_id, :payable_type
  validates_inclusion_of :kind, in: KINDS, message: "%{value} is not a valid kind of payment"
  validates_inclusion_of :source, in: SOURCES, message: "%{value} is not a valid source of payment"
  validates_numericality_of :amount

  after_create :make_payment!

  scope :bank_transfer, where(kind: 'bank_transfer')
  scope :credit_card,   where(kind: 'credit_card')
  scope :cash,          where(kind: 'cash')
  scope :unspecified,   where(kind: 'unspecified')

  scope :manual,          where(source: 'manual')
  scope :import,          where(source: 'import')
  scope :pay_on_delivery, where(source: 'pay_on_delivery')

  scope :reversed, where(reversed: true)

  default_value_for :reversed, false
  default_value_for :kind,     'unspecified'
  default_value_for :source,   'manual'
  default_value_for :display_time do
    Time.current
  end

  def reverse_payment!
    raise "This payment has already been reversed." if self.reversal_transaction.present?

    self.reversed = true
    self.reversed_at = Time.current

    options = { description: "[REVERSED] " + self.description, display_time: self.display_time }
    self.reversal_transaction = self.account.subtract_from_balance(self.amount, options)

    self.save

    return self.reversal_transaction
  end

  def manual?
    source == 'manual'
  end

  private

  def make_payment!
    raise "This payment has already been applied!" if self.transaction.present?

    self.transaction = account.add_to_balance(
      amount,
      transactionable: self,
      description: description,
      display_time: display_time
    )

    self.save

    return self.transaction
  end
end
