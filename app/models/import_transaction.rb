class ImportTransaction < ActiveRecord::Base

  belongs_to :import_transaction_list
  has_one :distributor, through: :import_transaction_list
  belongs_to :customer

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :customer, :customer_id, :transaction_time, :amount_cents, :removed, :description, :confidence, :import_transaction_list, :match
  
  scope :ordered, order("transaction_time ASC")

  validate :customer_belongs_to_distributor

  
  MATCH_MATCHED = "matched"
  MATCH_UNABLE_TO_MATCH = "unable_to_match"
  MATCH_TYPES = {MATCH_MATCHED => 0,
                 "not_a_customer" => 1,
                 "duplicate" => 2,
                 MATCH_UNABLE_TO_MATCH => 3}
  MATCH_SELECT = MATCH_TYPES.except(MATCH_MATCHED).collect{|symbol, index| [symbol.humanize, symbol]}


  def self.new_from_row(row, import_transaction_list, distributor)
    match_result = row.single_customer_match(distributor)
    customer = match_result.customer if match_result.present?
    confidence = match_result.confidence if match_result.present?
    ImportTransaction.new(
      customer: customer,
      transaction_time: row.date,
      amount_cents: row.amount * 100,
      removed: false,
      description: row.description,
      confidence: confidence,
      import_transaction_list: import_transaction_list
    )
  end

  def row
    Bucky::TransactionImports::Row.new(transaction_time, description, amount_cents)
  end

  def possible_customers
    result = customer.present? ? [[customer.badge, customer.id]] : []
    result += (MATCH_SELECT +
               distributor.customers.reject{|c| c.id == customer_id}.collect{|c|
                 [c.badge, c.id]
               })
    result
  end

  def confidence
    self[:confidence] || 0
  end

  def match=(m)
    m = MATCH_TYPES[MATCH_MATCHED] if m.blank?
    raise "#{m} was not in #{MATCH_TYPES}" unless MATCH_TYPES.include?(m)
    write_attribute :match, MATCH_TYPES[m]
  end

  def match
    MATCH_TYPES.key(read_attribute(:match))
  end

  def match_id
    customer_id || match
  end

  private
  
  def customer_belongs_to_distributor
    errors.add(:base, "Customer isn't known to this distributor") unless customer_id.blank? || distributor.customer_ids.include?(customer_id)
  end
end
