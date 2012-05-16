module Bucky::TransactionImports
  class Row

    include ActiveModel::Validations

    attr_accessor :date_string, :amount, :description

    validates :amount, numericality: true
    validates :date_string, presence: true
    validates :description, presence: true

    AMOUNT_REGEX = /\A[+-]?\d+?(\.\d+)?\Z/
    
    def initialize(date_string, description, amount)
      @date_string = date_string
      @description = description
      if amount.present? && (amount.is_a?(Integer) || amount.is_a?(Float) || amount.match(AMOUNT_REGEX))
        @amount = amount.to_f
      end
    end

    def date
      Date.parse(@date_string)
    end
    
    MATCH_STRATEGY = [[:previous_match, 1.0],
                      [:number_match, 1.0],
                      [:name_match, 0.8],
                      [:account_match, 0.7]]

    # Returns a number 0.0 -> 1.0 indicating how confident we
    # are that this payment comes from customer
    # 0.0 no confidence
    # 1.0 total confidence
    def match_confidence(customer)
      current_confidence = 0.0
      MATCH_STRATEGY.each do |method, confidence|
        current_confidence += self.send(method, customer) * confidence
        break if current_confidence > 0.8
      end
      current_confidence
    end

    def previous_match(customer)
      0.0
    end

    def number_match(customer)
      number_reference.collect do |number_reference|
        if customer.formated_number == number_reference
          1
        else
          0
        end
      end.sort.last || 0
    end

    def name_match(customer)
      regex = Regexp.new(customer.name.gsub(/\W+/, ".*"), true)
      if description.match(regex)
        1
      else
        regex = Regexp.new("#{customer.first_name.first} #{customer.last_name}".gsub(/\W+/, ".*"), true)
        description.match(regex).present? ? 0.90 : 0
      end
    end

    def account_match(customer)
      balance_match = Row.amount_match(amount, customer.account.balance.to_f)
      order_match = customer.orders.collect do |order|
        Row.amount_match(amount, order.price.to_f)
      end.sort.last || 0

      balance_match * 0.8 +
        order_match * 0.2
    end

    NUMBER_REFERENCE_REGEX = /(\d+)/
    def number_reference
      @possible_references ||= description.scan(NUMBER_REFERENCE_REGEX).to_a.flatten
    end

    # Return a number between 0.0 and 1.0
    # to indicate how close a match the numbers 
    # amount & balance are.
    # Check tests for examples
    def self.amount_match(amount, balance)
      result = if balance < 0
        balance *= -1
        if amount <= balance
          amount.to_f / balance.to_f
        else
          [0.0, 1.0 - (amount - balance).to_f / balance.to_f].max # make sure it doesn't go below 0
        end
      else
        0
      end
      if result < 0 || result > 1
        puts "======= WTF ======="
        puts "That shouldn't be #{result}"
        puts "#{amount}, #{balance}"
      else
        result
      end
    end

    def customers_match_with_confidence(customers)
      if not_customer? # Don't search for customers that match if we know its not going to match
        []
      else
        customers.collect{|customer|
          MatchResult.new(customer, match_confidence(customer))
        }.sort.select{|result|
          result.confidence > 0.7
        }.reverse
      end
    end

    def single_customer_match(distributor)
      matches = customers_match_with_confidence(distributor.customers)
      matches.first
    end

    def duplicate?(distributor)
      duplicates(distributor).present?
    end

    def duplicates(distributor)
      distributor.find_duplicate_import_transactions(date, description, amount)
    end

    def credit?
      amount > 0
    end

    def debit?
      !credit?
    end

    def not_customer?
      debit?
    end
      
    def to_s
      "#{date} #{description} #{amount}"
    end
    private

    def fuzzy_match(a, b)
      Bucky::Util.fuzzy_match(a, b)
    end
  end

  class MatchResult
    attr_accessor :customer, :confidence

    def initialize(customer, confidence)
      self.customer = customer
      self.confidence = confidence
    end

    def <=>(b)
      if self.confidence == b.confidence
        self.customer <=> b.customer
      else
        self.confidence <=> b.confidence
      end
    end
  end
end
