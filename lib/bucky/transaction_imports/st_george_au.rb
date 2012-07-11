module Bucky::TransactionImports
  class StGeorgeAu < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/st_george_au.csv"))
    
    set_columns :date, :description, :debit, :credit, :balance
    set_bank_name "St George Australia"
    set_header true

    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        next if skip?(row)
        date = row[i(:date)]
        description = row[i(:description)]
        debit = row[i(:debit)]
        credit = row[i(:credit)]
        amount = debit.present? ? ('-' + debit) : credit

        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end

    # Skip a row if it is not transaction data (Namely, it is Closing or Opening balance)
    def skip?(row)
    ["Closing Balance", "Opening Balance"].include?(row[i(:description)]) && 
      [row[i(:date)], row[i(:debit)], row[i(:credit)]].all?(&:blank?)
    end
  end
end
