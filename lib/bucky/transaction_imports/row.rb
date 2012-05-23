module Bucky::TransactionImports
  class Row

    include ActiveModel::Validations

    attr_accessor :date_string, :amount_string, :description, :index, :raw_data, :parser

    validate :row_is_valid

    def initialize(date_string, description, amount_string, index=nil, raw_data=nil, parser=nil)
      self.date_string = date_string
      self.description = description
      self.amount_string = amount_string
      self.index = index
      self.parser = parser
      self.raw_data = raw_data
    end

    def date
      Date.parse(@date_string)
    end

    def amount
      @amount_string.to_f
    end
    
    MATCH_STRATEGY = [[:email_match, 1.0],
                      [:number_match, 0.8],
                      [:name_match, 0.8],
                      [:account_match, 0.5]]

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
      [1.0, current_confidence].min
    end

    def previous_match(distributor)
      distributor.find_previous_match(description)
    end

    def email_match(customer)
      if customer.email.present? && description.match(Regexp.escape(customer.email))
        1.0
      else
        0.0
      end
    end

    def number_match(customer)
      number_reference.collect do |number_reference|
        if customer.formated_number == number_reference # Match the full 0014 to 0014
          1
        elsif customer.formated_number == ("%04d" % number_reference.to_i) # Match partial 14 -> 0014
          0.7
        else
          0
        end
      end.sort.last || 0 # Out of all the numbers in the description, pick the best match
    end

    def name_match(customer)
      regex = Regexp.new(Regexp.escape(customer.name).gsub(/\W+/, ".{0,3}"), true) # 0,3 means that it allows 0 -> 3 chars between the first and last name, be it a space or a dot or some other mistake
      if description.match(regex)
        # Match first and last name, ignoring case
        1
      elsif customer.has_first_and_last_name? # This fixes a bug where someone only has a first name (Say Phoenix) and the regex created is P.* which matches "payment" which isn't good!
        # Match first inital and last name
        regex = Regexp.new("#{Regexp.escape(customer.first_name.first)} #{Regexp.escape(customer.last_name)}".gsub(/\W+/, ".{0,3}"), true)
        description.match(regex).present? ? 0.9 : 0
      else
        0
      end
    end

    def account_match(customer)
      if amount == (-1.0 * customer.account.balance.to_f) && # Account matches amount (account must be negative)
        customer.distributor.accounts.where(["customers.id != ? AND accounts.balance_cents = ?", customer.id, -100 * amount]).count.zero? # No other accounts match the amount
        1.0
      else
        0
      end
    end

    NUMBER_REFERENCE_REGEX = / (\d+) /
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
          result.confidence >= 0.48
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

    def row_is_valid
      unless date_valid? && description_valid? && amount_valid?
        errors.add(:base, "The file you uploaded didn't match what we expected a #{parser.bank_name} file to look like.  There was a problem on row #{index}, make sure it matches the expected format #{parser.expected_format}")
      end
    end

    def date_valid?
      Date.parse(date_string) # Will throw ArgumentError: invalid date
      true
    rescue
      false
    end

    def description_valid?
      description.present?
    end

    AMOUNT_REGEX = /\A[+-]?\d+?(\.\d+)?\Z/
    def amount_valid?
      amount_string.present? && amount_string.match(AMOUNT_REGEX).present?
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
