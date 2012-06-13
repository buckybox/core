module Bucky::TransactionImports
  class Bnz < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/bnz.csv"))
    
    set_columns :date, :amount, :payee, :particulars, :code, :reference, :tran_type
    set_bank_name "BNZ"
    set_header true

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

  end
end
