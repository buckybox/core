module Bucky::TransactionImports
  class OmniImport
    def self.test_yaml
      <<EOY
        columns: date trans_type sort_code account_number description debt_amount credit_amount empty blank none
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

    def self.test_yaml2
      <<EOF
        columns: date desc debit credit balance
        DATE:
          date
        DESC:
          desc
        AMOUNT:
          not_blank:
            - negative: debit
            - credit
        options:
          - header:
        skip:
          - when:
              blank:
                - date
                - credit
                - debit
              match:
                - desc: Closing Balance
          - when:
              blank:
                - date
                - credit
                - debit
              match:
                - desc: Opening Balance

EOF
    end

    def self.test_file
      File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/uk_lloyds_tsb.csv")
    end

    def self.test_file2
      File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/st_george_au.csv")
    end

    def self.test_rows
      csv_read(test_file)
    end

    def self.test_hash
      YAML.load(test_yaml)
    end

    def self.csv_read(path)
      string = File.read(path)
      encoding = CharlockHolmes::EncodingDetector.detect(string)[:encoding]
      CSV.read(path, encoding: encoding)
    rescue CSV::MalformedCSVError => e #Handle stupid windows \r instead of \r\n csv files.  STANDARDS!
      raise e unless e.message == "Unquoted fields do not allow \\r or \\n (line 20)."
      CSV.parse(string.force_encoding(encoding).encode("UTF-8").gsub(/\r(?!\n)/, "\r\n"))
    end

    def self.csv_parse(string)
      encoding = CharlockHolmes::EncodingDetector.detect(string)[:encoding]
      CSV.parse(string, encoding: encoding)
    end

    def self.test
      OmniImport.new(test_rows, test_hash)
    end

    def self.test2
      OmniImport.new(csv_read(test_file2), YAML.load(test_yaml2))
    end
    
    attr_accessor :rows, :rules
    attr_accessor :column_names

    def initialize(rows, rules)
      self.rows = rows
      self.rules = Rules.new(OmniImport.convert_to_symbols(rules))
      self.column_names = self.rules.column_names
    end

    def process
      not_header_rows.collect do |row|
        begin
          rules.process(row)
        rescue StandardError => e
          raise OmniError.new("Issue on row: (#{row}) | #{e.message}")
        end
      end
    end

    def bucky_rows(bank_name)
      not_header_rows.collect.with_index do |row, index|
        begin
          create_bucky_row(rules.process(row), index, bank_name)
        rescue StandardError => e
          raise OmniError.new("Issue on row: (#{row}) | #{e.message}")
        end
      end
    end

    def create_bucky_row(row, index, bank_name)
      date = row[:DATE]
      desc = row[:DESC]
      amount = row[:AMOUNT].gsub(/[^\d.-]/,'')
      raw_data = row[:raw_data]
      Bucky::TransactionImports::Row.new(date, desc, amount, index, raw_data, self, bank_name)
    end

    def header_row
      result = header? ? rows[0] : []
      (longest_row_length - result.size).times{ result << ''}
      result
    end

    def not_header_rows
      start = header? ? 1 : 0
      start += option_value(:skip) if rules.has_option?(:skip)
      rows[start..-1].reject{|row| rules.skip?(row)}
    end

    def cleaned_rows
      header_row + not_header_rows
    end

    def header?
      rules.has_option?(:header)
    end

    def longest_row_length
      rows.collect{|r| r.size}.max
    end

    def empty_column_count
      longest_row_length - column_names.size
    end

    def process_row(row, keys=[])
      if keys.blank?
        rules.process(row)
      else
        processed = rules.process(row)
        returned_row = []
        keys.each do |key|
          returned_row << processed[key]
        end
        returned_row
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
      attr_accessor :column_names, :options
      attr_accessor :rhash, :responses
      attr_accessor :shash, :skip_rules

      def initialize(rhash)
        self.column_names = parse_columns(rhash)
        self.options = parse_options(rhash)
        self.rhash = rhash.except(:columns, :name, :options, :skip)
        self.shash = rhash[:skip]
        self.responses = {}
        self.skip_rules = []
        load_responses
        load_skip
      end

      def load_responses
        self.rhash.each do |response, rule_hash|
          responses.merge!(response.to_sym => Rule.create(rule_hash, self))
        end
      end

      def load_skip
        return if shash.blank?
        shash.each do |r|
          self.skip_rules << SkipRule.new(r[:when], self) unless r[:when].blank?
        end
      end

      def skip?(row)
        skip_rules.present? && skip_rules.any?{|r| r.skip?(row)} rescue false
      end

      def process(row)
        responses.inject({}){|result, (k,v)| result[k] = v.process(row); result}.merge(raw_data: raw_data(row))
      end

      def raw_data(row)
        column_names.reject{|cn| [:blank, :empty, :none].include?(cn)}.inject({}){|result, element| result.merge(element => get(row, element))}
      end

      def get(row, column_name_or_number)
        c = column_name_or_number
        if c.is_a?(Symbol)
          get_symbol(row, column_name_or_number)
        elsif c.is_a?(Fixnum)
          row[column_name_or_number]
        else
          raise OmniError.new('Expecting a number or column name as described by column_names:')
        end
      end

      def get_symbol(row, column_name_or_number)
        c = column_name_or_number
        if lookup(c).present?
          row[lookup(column_name_or_number)]
        elsif (match_data = c.to_s.match(/^c([01-9]+)$/)).present?# Expecting column numbers to be c0, c1, c999, etc.
          row[match_data[1].to_i] #Get column by integer
        else
          raise OmniError.new('Expecting a column name or cX where X is the row number')
        end
      end

      def lookup(column_name)
        @lookup_table ||= column_names.inject({}){|result, element| result.merge(element => result.size)}
        @lookup_table[column_name]
      end

      def has_option?(name)
        options.include?(name)
      end

      def option_value(name)
        options[name]
      end

      def parse_columns(rhash)
        return [] if rhash.blank?
        if rhash[:columns].present?
          if rhash[:columns].is_a?(Symbol)
            [rhash[:columns]]
          else
            OmniImport.convert_to_symbols(rhash[:columns].split(' '))
          end
        else
          []
        end
      end

      def parse_options(rhash)
        return {} if rhash.blank?
        if rhash[:options].present?
          options = rhash[:options]
          if options.is_a?(Symbol)
            [options]
          else
            OmniImport.convert_to_symbols(rhash[:options])
          end
        else
          {}
        end
      end
    end

    class Rule
      attr_accessor :rules, :parent

      delegate :get, to: :parent

      def self.create(rhash, parent)
        return RuleDirect.new(rhash, parent) if rhash.is_a?(Symbol)
        return RuleBlank.new if rhash.blank?

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
        if rhash.is_a?(Symbol)
          super(rhash, parent)
        elsif rhash.is_a?(Array)
          self.rules = []
          self.rules << Rule.create(rhash[0], parent)
          self.format = rhash[1][:format].to_s
        else
          self.format = rhash[:format].to_s
          super(rhash.except(:format), parent)
        end
      end

      def process(row)
        date_string = rule.process(row)
        if format.present?
          Date.strptime(date_string, format).strftime('%d/%m/%Y')
        else
          Date.parse(date_string).strftime('%d/%m/%Y') #Throws error if invalid
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

    class RuleBlank < Rule
      def initialize
      end

      def process(row)
        ""
      end
    end

    class SkipRule
      attr_accessor :blanks, :matches, :parent

      delegate :get, to: :parent
      
      def initialize(shash, parent)
        self.blanks = shash[:blank] if shash[:blank].is_a?(Array)
        self.matches = shash[:match].inject({}){|result, element| result.merge(element)} unless shash[:match].blank?
        self.parent = parent
      end

      def get(row, column_name_or_number)
        parent.get(row, column_name_or_number)
      end
      
      def to_s
        {blanks: blanks, matches: matches}.inspect
      end

      def skip?(row)
        if blanks.blank?
          if matches.blank?
            return false
          else
            matches_row?(row)
          end
        else
          if matches.blank?
            blanks.all?{|column| get(row, column).blank?}
          else
            matches_row?(row) &&
              blanks.all?{|column| get(row, column).blank?}
          end
        end
      end

      def matches_row?(row)
        matches.all? do |column, t|
          text = t.to_s
          if text[0] == '/' && text[-1] == '/'
            !!get(row, column).match(/#{text[1..-2]}/)
          else
            get(row, column) == text
          end
        end
      end
    end
  end

  class OmniError < StandardError
  end
end
