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
    @possible_references ||= description.scan(NUMBER_REFERENCE_REGEX).to_a.collect{|ref| "%04d" % ref}
  end

  def customer_match(distributor)
    customers = distributor.customers
    customer_references = customers.inject({}){|hash, c| hash.merge(c.formated_number => c)}
    matches = number_reference.collect{|ref| customer_references[ref]}
    matches.compact
  end
    

  private

  def fuzzy_match(a, b)
    Bucky::Util.fuzzy_match(a, b)
  end
end
