module Bucky::TransactionImports
  class Kiwibank < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/kiwibank.csv"))
    
    set_columns :date, :description, :empty, :amount, :balance
    set_bank_name "Kiwibank"
    set_header true
    
    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        add_row(*get_columns(row, :date, :description, :amount), index, raw_data(row), self)
        index += 1
      end

      rows
    end
  end
end
