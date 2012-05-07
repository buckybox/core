class ImportTransaction < ActiveRecord::Base

  belongs_to :import_transaction_list
  has_one :distributor, through: :import_transaction_list
  belongs_to :customer

  composed_of :amount,
    class_name: "Money",
    mapping: [%w(amount_cents cents), %w(currency currency_as_string)],
    constructor: Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    converter: Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  def self.new_from_row(row, distributor)
    customer_match, match_confidence = row.customers_match_with_confidence(distributor.customers).last
    customer_match_id = customer_match.id if customer_match.present?
    ImportTransaction.new({
      customer_id: customer_match_id,
      transaction_time: row.date,
      amount_cents: row.amount * 100,
      removed: false,
      description: row.description,
      customer_match: match_confidence,
      distributor: distributor
    })
  end

  def row
    Bucky::TransactionImports::Row.new(transaction_time, description, amount_cents)
  end

  def possible_customers
    possible_matches = row.customers_match_with_confidence(distributor.customers)
    if possible_matches.present?
      @best_match = possible_matches.first.first
      @best_match_confidence = possible_matches.first.last
    end
    
    everyone_else = if possible_matches.present?
                      distributor.customers.where(['customers.id not in (?)', possible_matches.collect{|m| m.first.id}])
                    else
                      distributor.customers
                    end
    ([["not a customer", :not_a_customer],
      ["duplicate", :duplicate],
      ["unable to match", :unable_to_match]].collect {|label, id|
        Struct.new(:badge, :id).new(label, id)
      } +
     possible_matches.collect(&:first) + everyone_else)
  end

  def best_match
    if amount > 0
      @best_match.try(:id) || :unable_to_match
    else
      :not_a_customer
    end
  end

  def best_match_confidence
    @best_match_confidence || 0
  end
end
