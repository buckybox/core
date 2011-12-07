class Payment < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :customer
  belongs_to :account

  composed_of :amount,
    :class_name => "Money",
    :mapping => [%w(amount_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :distributor, :customer, :account, :amount, :kind, :description
  
  KINDS = %w(bank_transfer credit_card)

  validates_presence_of :distributor, :customer, :account, :amount, :kind, :description
  validates_inclusion_of :kind, :in => KINDS, :message => "%{value} is not a valid kind of payment"

  after_save :update_account

  def update_account
    account.add_to_balance(amount, :kind => 'payment', :description => "[ID##{id}] Recieved a payment by #{kind.humanize.downcase}.")
    account.save
  end
end
