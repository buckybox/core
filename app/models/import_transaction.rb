class ImportTransaction < ActiveRecord::Base

  belongs_to :import_transaction_list
  has_one :distributor, through: :import_transaction_list
  belongs_to :customer
  belongs_to :payment

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  attr_accessible :customer, :customer_id, :transaction_date, :amount_cents, :removed, :description, :confidence, :import_transaction_list, :match, :draft
  
  MATCH_MATCHED = "matched"
  MATCH_UNABLE_TO_MATCH = "unable_to_match"
  MATCH_DUPLICATE = "duplicate"
  MATCH_NOT_A_CUSTOMER = "not_a_customer"
  MATCH_TYPES = {MATCH_MATCHED => 0,
                 MATCH_NOT_A_CUSTOMER => 1,
                 MATCH_DUPLICATE => 2,
                 MATCH_UNABLE_TO_MATCH => 3}
  MATCH_SELECT = MATCH_TYPES.except(MATCH_MATCHED).collect{|symbol, index| [symbol.humanize, symbol]}

  scope :ordered, order("transaction_date ASC, created_at ASC")
  scope :draft, where(['import_transactions.draft = ?', true])
  scope :processed, where(['import_transactions.draft = ?', false])

  scope :matched, where(["match = ?", MATCH_TYPES[MATCH_MATCHED]])
  scope :not_matched, where(["match != ?", MATCH_TYPES[MATCH_MATCHED]])

  scope :unable_to_match, where(["match = ?", MATCH_TYPES[MATCH_UNABLE_TO_MATCH]])
  scope :not_unable_to_match, where(["match != ?", MATCH_TYPES[MATCH_UNABLE_TO_MATCH]])

  scope :duplicate, where(["match = ?", MATCH_TYPES[MATCH_DUPLICATE]])
  scope :not_duplicate, where(["match != ?", MATCH_TYPES[MATCH_DUPLICATE]])

  scope :not_a_customer, where(["match = ?", MATCH_TYPES[MATCH_NOT_A_CUSTOMER]])
  scope :not_not_a_customer, where(["match != ?", MATCH_TYPES[MATCH_NOT_A_CUSTOMER]])

  validate :customer_belongs_to_distributor

  after_validation :update_account, if: :changed?
  
  def self.new_from_row(row, import_transaction_list, distributor)
    match_result = row.single_customer_match(distributor)
    ImportTransaction.new(
      customer: match_result.customer,
      transaction_date: row.date,
      amount_cents: (row.amount * 100).to_i,
      removed: false,
      description: row.description,
      confidence: match_result.confidence,
      import_transaction_list: import_transaction_list,
      match: match_type(match_result),
      draft: true
    )
  end

  def self.match_type(match_result)
    case match_result.type
    when :match
      MATCH_MATCHED
    when :duplicate
      MATCH_DUPLICATE
    when :not_a_customer
      MATCH_NOT_A_CUSTOMER
    when :unable_to_match
      MATCH_UNABLE_TO_MATCH
    else
      raise "MatchResult didn't have a valid type - #{match_result.inspect}"
    end
  end

  def row
    Bucky::TransactionImports::Row.new(transaction_date, description, amount_cents)
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
    raise "#{m} was not in #{MATCH_TYPES}" unless MATCH_TYPES.include?(m)
    write_attribute :match, MATCH_TYPES[m]
  end

  def match
    MATCH_TYPES.key(read_attribute(:match))
  end

  def match_id
    customer_id || match
  end

  def is_matched?
    match == MATCH_MATCHED && customer.present?
  end

  def customer_was
    distributor.customers.find_by_id(customer_id_was)
  end

  def payment_created?
    payment.present?
  end

  private

  def update_account
    # Undo payment to the previous matched customer if they are no longer the match
    if customer_id_changed? && customer_was.present? && payment_created?
      self.payment.reverse_payment!
      self.payment = nil
    end

    # Create new payments if a new customer has been assigned
    if !draft && is_matched? && !payment_created? && customer.present?
      self.payment = customer.make_import_payment(amount, description, transaction_date) 
    end
  end
  
  def customer_belongs_to_distributor
    errors.add(:base, "Customer isn't known to this distributor") unless customer_id.blank? || distributor.customer_ids.include?(customer_id)
  end
end
