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
    
    MATCH_STRATEGY = [[:number_match, 1.0],
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

    def previous_match(distributor)
      distributor.find_previous_match(description)
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
          MatchResult.customer_match(customer, match_confidence(customer))
        }.sort.select{|result|
          result.confidence > 0.7
        }.reverse
      end
    end

    def single_customer_match(distributor)
      if duplicate?(distributor)
        MatchResult.duplicate_match(1.0)
      elsif not_customer?
        MatchResult.not_a_customer(1.0)
      elsif (@prev_match = previous_match(distributor)).present?
        MatchResult.customer_match(@prev_match.customer, 1.0)
      else
        matches = customers_match_with_confidence(distributor.customers)
        match = matches.first
        match.present? ? match : MatchResult.unable_to_match
      end
    end

    def duplicate?(distributor)
      duplicates(distributor).count != 0
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
    attr_accessor :customer, :confidence, :type
    
    def initialize(customer, confidence, type)
      self.customer = customer
      self.confidence = confidence
      self.type = type
    end

    def self.customer_match(customer, confidence)
      MatchResult.new(customer, confidence, :match)
    end

    def self.duplicate_match(confidence)
      MatchResult.new(nil, confidence, :duplicate)
    end

    def self.not_a_customer(confidence)
      MatchResult.new(nil, confidence, :not_a_customer)
    end

    def self.unable_to_match
      MatchResult.new(nil, 0.0, :unable_to_match)
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
