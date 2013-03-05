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
          - no_header
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
    attr_accessor :column_names, :bank_name, :options
    OPTIONS = [:no_header]

    def initialize(rows, rules)
      self.rows = rows
      self.rules = Rules.new(convert_to_symbols(rules))
      self.column_names = self.rules.column_names
      self.bank_name = self.rules.bank_name
      self.options = self.rules.options
    end

    # Recursively symbolize keys unless the string is broken with spaces
    def convert_to_symbols(rules)
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
        self.column_names = rhash[:columns].split(' ')
        self.bank_name = rhash[:name]
        self.options = rhash[:options]
        self.rhash = rhash.except(:columns, :name, :options)
        self.responses = {}
        load_responses
      end

      def load_responses
        self.rhash.each do |response, rule_hash|
          responses.merge!(response.to_sym => Rule.new(rule_hash, self))
        end
      end

      def process(row)
        rules.process(row)
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
    end

    class Rule
      TYPES = [:merge, :not_blank, :negative, date_parse: [:format]]
      
      attr_accessor :rules, :parent

      delegate :get, to: :parent

      def initialize(rhash, parent)
        self.parent = parent
        self.rules = []

        rhash.each do |key, value|
          case key
          when :date_parse
            rules << RuleDateParse.new(value, self)
          end
        end
      end

      def get(row, column_name_or_number)
        parent.get(row, column_name_or_number)
      end

      def process(row)
        rules.collect{|r| r.process(row)}
      end

      def to_s
        rules.to_s
      end
    end

    class RuleDateParse < Rule
      attr_accessor :column, :format
      def initialize(rhash, parent)
        self.column = rhash.except(:format).keys.first
        self.format = rhash[:format].to_s
        self.parent = parent
      end

      def process(row)
        date_string = get(row, column)
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
  end
end
