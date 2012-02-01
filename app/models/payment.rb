class Payment < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :account

  has_one :customer, :through => :account

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :account, :account_id, :amount, :kind, :description, :distributor, :statement_id, :reference

  KINDS = %w(bank_transfer credit_card manual)

  validates_presence_of :distributor, :account, :amount, :kind, :description
  validates_inclusion_of :kind, :in => KINDS, :message => "%{value} is not a valid kind of payment"
  validates_numericality_of :amount, :greater_than => 0

  after_create :update_account

  scope :bank_transfer, where(:kind => 'bank_transfer')
  scope :credit_card, where(:kind => 'credit_card')
  scope :manual, where(:kind => 'manual')

  def update_account
    account.add_to_balance(amount, :kind => 'payment', :description => "[ID##{id}] Recieved a payment by #{kind.humanize.downcase}.")
    account.save
  end
end
