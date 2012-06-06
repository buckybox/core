module Bucky::TransactionImports
  class Bnz < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/bnz.csv"))
    
    COLUMNS = [:date, :amount, :payee, :particulars, :code, :reference, :tran_type]

    def expected_format
      "DATE, AMOUNT, PAYEE, PARTICULARS, CODE, REFERENCE, TRAN TYPE.  First row is ignored (header)."
    end

    def bank_name
      "BNZ"
    end
    
    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = concat(row, :payee, :particulars, :code, :reference)
        amount = row[i(:amount)]

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

    def concat(row, *columns)
      columns.collect{|c| row[i(c)] }.join(" ")
    end
  end
end
