class Account < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :customer

  has_many :orders
  has_many :payments
  has_many :transactions

  composed_of :balance,
    :class_name => "Money",
    :mapping => [%w(balance_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :distributor, :customer

  before_validation :default_balance_and_currency

  validates_presence_of :distributor, :customer, :balance
  validates_uniqueness_of :customer_id, :scope => :distributor_id, :message => 'this customer already has an account with this distributor'

  def default_balance_and_currency
    write_attribute(:balance_cents, 0) if balance_cents.blank?
    write_attribute(:currency, Money.default_currency.to_s) if currency.blank?
  end

  def balance_cents=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end
  
  def balance=(value)
    raise(ArgumentError, "The balance can not be updated this way. Please use one of the model balance methods that create transactions.")
  end

  def change_balance_to(amount, options = {})
    amount = amount.to_money
    amount_difference = amount - balance

    options.merge!(kind: 'amend') unless options[:kind]
    options.merge!(description: "Balance changed from #{balance} to #{amount}.") unless options[:description]

    write_attribute(:balance_cents, amount.cents)
    write_attribute(:currency, amount.currency.to_s || Money.default_currency.to_s)
    clear_aggregation_cache # without this the composed_of balance attribute does not update

    transactions.build(kind: options[:kind], amount: amount_difference, description: options[:description])
  end

  def add_to_balance(amount, options = {})
    new_balance = balance + amount.to_money
    change_balance_to(new_balance, options)
  end

  def subtract_from_balance(amount, options = {})
    add_to_balance((amount * -1), options)
  end
end
