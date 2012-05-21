module Bucky::TransactionImports
  class Paypal < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/paypal.csv"))
    
    COLUMNS = [:date, :time, :time_zone, :name, :type, :status, :currency, :amount, :net]

    def expected_format
      "DATE , DESCRIPTION, ignored, AMOUNT.  With first row ignored"
    end

    def bank_name
      "Paypal"
    end
  end
end
