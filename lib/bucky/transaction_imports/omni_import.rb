module Bucky::TransactionImports
  class OmniImport
    def self.test_yaml
      <<EOY
        columns: date trans_type sort_code account_number description debt_amount credit_amount
        name: Lloyds TSB
        DATE:
          date_parse:
            c0:
            format: '%d/%m/%Y'
        DESC:
          not_blank:
            - merge:
              - trans_type
              - sort_code
              - account_number
              - description
            - trans_type
        AMOUNT:
          not_blank:
            - negative: c5
            - c6
        options:
          - header
EOY
    end

    def self.test_file
      File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/uk_lloyds_tsb.csv"))
    end

    def self.test_rows
      CSV.read(test_file)
    end

    def self.test_hash
      YAML.load(test_yaml)
    end

    def self.test
      OmniImport.new(test_rows, test_hash)
    end
    
    attr_accessor :rows, :rules
    attr_accessor :column_names, :bank_name
    OPTIONS = [:no_header]

    def initialize(rows, rules)
      self.rows = rows
      self.rules = Rules.new(OmniImport.convert_to_symbols(rules))
      self.column_names = self.rules.column_names
      self.bank_name = self.rules.bank_name
    end

    def process
      start = rules.has_option?(:no_header) ? 0 : 1
      rows[start..-1].collect do |row|
        begin
          rules.process(row)
        rescue Exception => e
          raise "Issue on row: (#{row}) | #{e.message}"
        end
      end
    end

    # Recursively symbolize keys unless the string is broken with spaces
    def self.convert_to_symbols(rules)
      if rules.is_a?(Hash)
        rules.inject({}){|memo,(k,v)| memo[k.to_sym] = convert_to_symbols(v); memo}
      elsif rules.is_a?(Array)
        rules.collect{|v| convert_to_symbols(v)}
      elsif rules.is_a?(String) && !rules.include?(' ')
        rules.to_sym
      else
        rules
      end
    end

    class Rules
      attr_accessor :rhash
      attr_accessor :column_names, :bank_name, :options
      attr_accessor :responses

      def initialize(rhash)
        self.column_names = OmniImport.convert_to_symbols(rhash[:columns].split(' '))
        self.bank_name = rhash[:name]
        self.options = OmniImport.convert_to_symbols(rhash[:options])
        self.rhash = rhash.except(:columns, :name, :options)
        self.responses = {}
        load_responses
      end

      def load_responses
        self.rhash.each do |response, rule_hash|
          responses.merge!(response.to_sym => Rule.create(rule_hash, self))
        end
      end

      def process(row)
        responses.inject({}){|result, (k,v)| result[k] = v.process(row); result}
      end

      def get(row, column_name_or_number)
        c = column_name_or_number
        if c.is_a?(Symbol)
          get_symbol(row, column_name_or_number)
        elsif c.is_a?(Fixnum)
          row[column_name_or_number]
        else
          raise 'Expecting a number or column name as described by column_names:'
        end
      end

      def get_symbol(row, column_name_or_number)
        c = column_name_or_number
        if lookup(c).present?
          row[lookup(column_name_or_number)]
        elsif (match_data = c.to_s.match(/^c([01-9]+)$/)).present?# Expecting column numbers to be c0, c1, c999, etc.
          row[match_data[1].to_i] #Get column by integer
        else
          raise 'Expecting a column name or cX where X is the row number'
        end
      end

      def lookup(column_name)
        @lookup_table ||= column_names.inject({}){|result, element| result.merge(element => result.size)}
        @lookup_table[column_name]
      end

      def has_option?(name)
        options.include?(name)
      end
    end

    class Rule
      TYPES = [:merge, :not_blank, :negative, date_parse: [:format]]
      
      attr_accessor :rules, :parent

      delegate :get, to: :parent

      def self.create(rhash, parent)
        return RuleDirect.new(rhash, parent) if rhash.is_a?(Symbol)

        rhash.each do |key, value|
          case key
          when :date_parse
            return RuleDateParse.new(value, parent)
          when :not_blank
            return RuleNotBlank.new(value, parent)
          when :negative
            return RuleNegative.new(value, parent)
          when :merge
            return RuleMerge.new(value, parent)
          else
            return RuleDirect.new(key, parent)
          end
        end
      end
      
      def initialize(rhash, parent)
        self.rules = []
        if rhash.is_a?(Array) || rhash.is_a?(Hash)
          rhash.each do |rule| # Order is important here, as the first NON blank rule is returned
            self.rules << Rule.create(rule, parent)
          end
        else
          self.rules << Rule.create(rhash, parent)
        end
        self.parent = parent
      end

      def get(row, column_name_or_number)
        parent.get(row, column_name_or_number)
      end
      
      # Assumes the rule only has one child
      def rule
        rules.first
      end

      def to_s
        rules.to_s
      end
    end

    class RuleDirect < Rule
      attr_accessor :column
      def initialize(rhash, parent)
        self.column = rhash
        self.parent = parent
      end

      def process(row)
        get(row, column)
      end
    end

    class RuleDateParse < Rule
      attr_accessor :format
      def initialize(rhash, parent)
        self.format = rhash[:format].to_s
        super(rhash.except(:format), parent)
      end

      def process(row)
        date_string = rule.process(row)
        if format.present?
          Date.strptime(date_string, format).strftime('%d/%m/%Y')
        else
          Date.parse(date_string) #Throws error if invalid
          date_string
        end
      end

      def to_s
        if format.present?
          "#{column}: #{format}"
        else
          column
        end
      end
    end

    class RuleNotBlank < Rule
      def process(row)
        rules.each do |r|
          result = r.process(row)
          return result unless result.blank?
        end
        nil
      end
    end

    class RuleMerge < Rule
      def process(row)
        rules.collect{|r| r.process(row)}.join(' ')
      end
    end

    class RuleNegative < Rule
      def process(row)
        result = rule.process(row)
        if result.blank?
          result
        else
          "-#{result}"
        end
      end
    end
  end
end
