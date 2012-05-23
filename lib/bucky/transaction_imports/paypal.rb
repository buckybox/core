module Bucky::TransactionImports
  class Paypal < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/paypal.csv"))
    
    COLUMNS = [:date, :time, :time_zone, :name, :type, :status, :currency, :gross, :fee, :net, :from_email_address, :to_email_address, :transaction_id]

    def expected_format
      "DATE, TIME, TIME ZONE, NAME, TYPE, STATUS, CURRENCY, GROSS, FEE, NET, FROM EMAIL ADDRESS, TO EMAIL ADDRESS, TRANSACTION ID.  First row ignored (headers)."
    end

    def bank_name
      "Paypal"
    end
    
    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = row[i(:from_email_address)]
        amount = row[i(:gross)]
        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end

    def raw_data(row)
      COLUMNS.inject({}) do |hash, element|
        hash.merge(element => row[i(element)])
      end
    end

    def i(column)
      COLUMNS.index(column)
    end
  end
end
