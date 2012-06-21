module Bucky::TransactionImports
  class CsvImport
    require 'csv'
    
    include ActiveModel::Validations

    attr_accessor :rows

    validate :rows_are_valid

    def import(file)
      import_csv(File.read(file))
    end
    
    def import_csv(csv)
      raise "This method needs to be defined in a child class"
      # and call add_row(date, description, amount, row_index, parser_instance)
    end

    def expected_format
      raise "This method needs to be defined in a child class"
    end
    
    def bank_name
      raise "This method needs to be defined in a child class"
    end
    
    def add_row(date, description, amount, index, raw_data, parser)
      rows << Row.new(date, description, amount, index, raw_data, parser)
    end

    def credit_rows
      @credit_rows ||= rows.select(&:credit?)
    end

    def debit_rows
      @debit_rows ||= rows.select(&:debit?)
    end

    def rows_are_valid
      unless rows.all?(&:valid?)
        errors.add(:base, "There was a problem with the file you uploaded.")
      end
    end

    def rows
      @rows ||= []
      @rows
    end

    def self.set_columns(*cols)
      @columns = cols
    end
    def self.columns
      @columns
    end
    def columns
      self.class.columns
    end
    
    def self.set_bank_name(name)
      @bank_name = name
    end
    def self.bank_name
      @bank_name
    end
    def bank_name
      self.class.bank_name
    end

    def self.set_header(bool)
        return @header = bool
    end
    def self.header?
      @header
    end
    def header?
      self.class.header?
    end
    
    def raw_data(row)
      (columns-[:empty]).inject({}) do |hash, element|
        hash.merge(element => row[i(element)])
      end
    end

    def i(col)
      columns.index(col)
    end

    def concat(row, *cols)
      cols.collect{|c| row[i(c)] }.join(" ")
    end
    
    # Given a CSV row and a list of columns (:date, :description, :amount)
    # Return those columns values defined in COLUMNS as an array from
    # the row
    def get_columns(row, *cols)
      result = []
      cols.each do |col|
        result << row[columns.index(col)]
      end
      result
    end

    def expected_format
      response = columns.collect{|col| col == :empty ? "IGNORED" : col.to_s.upcase}.join(", ") + "."
      response += "  First row is " + (header? ? "ignored (header)." : "included (no header).")
      response
    end

  end
end
