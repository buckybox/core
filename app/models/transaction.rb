class Transaction < ActiveRecord::Base
  belongs_to :account
  belongs_to :transactionable, polymorphic: true
  belongs_to :reverse_transactionable, polymorphic: true

  monetize :amount_cents

  attr_accessible :account, :transactionable, :amount, :description, :display_time, :reverse_transactionable

  validates_presence_of :account_id, :transactionable_id, :transactionable_type, :amount, :description, :display_time

  scope :ordered_by_display_time, order('transactions.display_time DESC, transactions.created_at DESC')
  scope :ordered_by_created_at, order('transactions.created_at DESC')
  scope :payments, where("amount_cents > 0")

  default_value_for :display_time do
    Date.current
  end

  def manual?
    transactionable_type == 'Account' || transactionable.manual? if transactionable
  end

  def customer
    account.customer
  end

  def self.dummy(amount, description, date)
    OpenStruct.new(
      description: description,
      amount: CrazyMoney.zero,
      created_at: date,
      display_time: date,
      id: 999999999
    )
  end
end
