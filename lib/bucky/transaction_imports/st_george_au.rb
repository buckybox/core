module Bucky::TransactionImports
  class StGeorgeAu < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/st_george_au.csv"))
    
    COLUMNS = [:date, :description, :debit, :credit, :balance]

    def expected_format
      "DATE , DESCRIPTION, DEBIT, CREDIT, BALANCE.  The first row is ignored."
    end

    def bank_name
      "St George Australia"
    end
    
    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = row[i(:description)]
        debit = row[i(:debit)]
        credit = row[i(:credit)]
        amount = debit.present? ? ('-' + debit) : credit

        add_row(date, description, amount, index, self)
        index += 1
      end

      rows
    end

    def i(column)
      COLUMNS.index(column)
    end
  end
end
