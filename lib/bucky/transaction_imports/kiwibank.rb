module Bucky::TransactionImports
  require 'csv'

  class Kiwibank
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/kiwibank.csv"))
    
    COLUMNS = [:date, :description, :empty, :amount]

    attr_accessor :rows

    def import(file)
      import_csv(File.read(file))
    end

    def import_csv(csv)
      transaction_rows = []
      CSV.parse(csv, headers: true) do |row|
        add_row(Row.new(*get_columns(row, :date, :description, :amount)))
      end

      rows
    end

    def add_row(row)
      @rows ||= []
      @rows << row
    end

    def credit_rows
      @credit_rows ||= rows.select(&:credit?)
    end

    def debit_rows
      @debit_rows ||= rows.select(&:debit?)
    end

    def valid?
      @rows.all?(&:valid?)
    end

    def errors
      Struct.new(:full_messages).new(@rows.collect{|r| r.errors.blank? ? nil : r.to_s + " " + r.errors.full_messages.join(', ')}.select(&:present?))
    end

    # Given a CSV row and a list of columns (:date, :description, :amount)
    # Return those columns values defined in COLUMNS as an array from
    # the row
    def get_columns(row, *columns)
      result = []
      columns.each do |column|
        result << row[COLUMNS.index(column)]
      end
      result
    end
  end
end
