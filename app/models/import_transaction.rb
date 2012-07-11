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

  attr_accessible :customer, :customer_id, :transaction_date, :amount_cents, :removed, :description, :confidence, :import_transaction_list, :match, :draft, :raw_data

  serialize :raw_data

  MATCH_MATCHED = "matched"
  MATCH_UNABLE_TO_MATCH = "unable_to_match"
  MATCH_DUPLICATE = "don't import (duplicate detected)"
  MATCH_NOT_A_CUSTOMER = "not_a_customer / match_later"
  MATCH_TYPES = {MATCH_MATCHED => 0,
                 MATCH_NOT_A_CUSTOMER => 1,
                 MATCH_DUPLICATE => 2,
                 MATCH_UNABLE_TO_MATCH => 3}
  MATCH_SELECT = MATCH_TYPES.except(MATCH_MATCHED).collect{|symbol, index| [symbol.humanize, symbol]}

  scope :ordered, order("transaction_date DESC, created_at DESC")
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

  scope :removed, where(removed: true)
  scope :not_removed, where(removed: false)

  validate :customer_belongs_to_distributor

  after_validation :update_account, if: :changed?

  delegate :account, to: :import_transaction_list

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
      draft: true,
      raw_data: row.raw_data
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
    result += draft? ? MATCH_SELECT : [[MATCH_NOT_A_CUSTOMER.humanize, MATCH_NOT_A_CUSTOMER]]
    result += distributor.customers.reject{|c| c.id == customer_id}.collect { |c| [c.badge, c.id] }

    return result
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

  def matched?
    match == MATCH_MATCHED && customer.present?
  end

  def duplicate?
    match == MATCH_DUPLICATE
  end

  def customer_was
    distributor.customers.find_by_id(customer_id_was)
  end

  def payment_created?
    payment.present?
  end

  def raw_data
    read_attribute(:raw_data) || {}
  end

  def remove!
    return true if removed?

    ImportTransaction.transaction do
      payment.reverse_payment! if payment.present?
      self.removed = true
      save!
    end
  end

  def self.process_attributes(transaction_attributes)
    if ImportTransaction::MATCH_TYPES.include?(transaction_attributes['customer_id'])
      transaction_attributes['match'] = transaction_attributes['customer_id']
      transaction_attributes['customer_id'] = nil
    else
      transaction_attributes['match'] = ImportTransaction::MATCH_MATCHED
    end

    return transaction_attributes
  end

  def payment_type
    if matched?
      case account
      when 'Paypal'
        'Paypal'
      else
        'Bank Deposit'
      end
    else
      ''
    end
  end

  def confidence_high?
    confidence >= 0.75
  end

  def confidence_middle?
    !confidence_high && !confidence_low
  end

  private

  def update_account
    # Undo payment to the previous matched customer if they are no longer the match
    if customer_id_changed? && customer_was.present? && payment_created?
      self.payment.reverse_payment!
      self.payment = nil
    end

    # Create new payments if a new customer has been assigned
    if !draft && matched? && !payment_created? && customer.present?
      self.create_payment(
        distributor: distributor,
        account: customer.account,
        amount: amount,
        kind: 'unspecified',
        source: 'import',
        description: "Payment made by #{payment_type}",
        display_time: transaction_date.to_time_in_current_zone,
        payable: self
      )
    end
  end

  def customer_belongs_to_distributor
    errors.add(:base, "Customer isn't known to this distributor") unless customer_id.blank? || distributor.customer_ids.include?(customer_id)
  end
end
