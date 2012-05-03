class Bucky::TransactionImports::Row

  include ActiveModel::Validations

  attr_accessor :date_string, :amount, :description

  validates :amount, presence: true, numericality: true
  validates :date_string, presence: true
  validates :description, presence: true

  AMOUNT_REGEX = /\A[+-]?\d+?(\.\d+)?\Z/
  
  def initialize(date_string, description, amount)
    @date_string = date_string
    @description = description
    if amount.match(AMOUNT_REGEX)
      @amount = amount.to_f
    end
  end

  def date
    Date.parse(@date_string)
  end

  NUMBER_REFERENCE_REGEX = /#(\d+)/
  def number_reference
    @possible_references ||= description.scan(NUMBER_REFERENCE_REGEX).to_a.flatten
  end

  def reference_customer_matches(customers)
    customer_references = customers.inject({}){|hash, c| hash.merge(c.formated_number => c)}
    matches = number_reference.collect{|ref| customer_references[ref]}
    matches.compact
  end

  def account_customer_matches(customers)
    account_matches = customers.select do |customer|
      customer.account.balance.to_f == amount
    end

    if account_matches.size == 1
      account_matches
    else
      customers
    end
  end

  def customer_match(customer)
    ref_confidence = customer_match_reference(customer)
    balance_confidence = customer_match_balance(customer)
    order_price_confidence = customer_order_price_match(customer)

    ref_confidence * 0.8 +
      balance_confidence * 0.15 +
      order_price_confidence * 0.05
  end

  def customer_match_reference(customer)
    number_reference.collect do |number_reference|
      fuzzy_match(customer.formated_number, number_reference)
    end.sort.last
  end

  # Check amount from row and compare to customer account balance
  def customer_match_balance(customer)
    Row.amount_match(amount, customer.account.balance.to_f)
  end

  # Check current order prices against row amount
  def customer_order_price_match(customer)
    customer.orders.collect do |order|
      Row.amount_match(amount, order.price.to_f)
    end.sort.last
  end

  # Return a number between 0.0 and 1.0
  # to indicate how close a match the numbers 
  # amount & balance are.
  # Check tests for examples
  def self.amount_match(amount, balance)
    if amount <= balance
      amount.to_f / balance.to_f
    else
      [0.0, 1.0 - (amount - balance).to_f / balance.to_f].max # make sure it doesn't go below 0
    end
  end

  def customers_match_with_confidence(customers)
    customers.collect{|customer|
      [customer, customer_match(customer)]
    }.sort_by(&:last).select{|match|
      match.last > 0.7
    }.reverse
  end

  def customers_match(distributor)
    customers_match_with_confidence(distributor.customers).collect(&:first).sort_by(&:formated_number)
  end

  def single_customer_match(distributor)
    customers_match_with_confidence(distributor.customers).collect(&:first).first
  end
    

  private

  def fuzzy_match(a, b)
    Bucky::Util.fuzzy_match(a, b)
  end
end
