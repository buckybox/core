module Bucky::TransactionImports
  class Kiwibank < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/kiwibank.csv"))
    
    COLUMNS = [:date, :description, :empty, :amount, :balance]
    
    def expected_format
      "(DATE , DESCRIPTION, ignored, AMOUNT).  With first row ignored"
    end

    def bank_name
      "Kiwibank"
    end
    
    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        add_row(*get_columns(row, :date, :description, :amount), index, raw_data(row), self)
        index += 1
      end

      rows
    end

    def raw_data(row)
      COLUMNS.inject({}) do |hash, element|
        hash.merge(element => row[COLUMNS.index(column)])
      end
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
