module Bucky::TransactionImports
  class ReoUk < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/reo_uk.csv"))
    
    set_columns :date, :tran_type, :sort_code, :account_number, :description, :debt_amount, :credit_amount
    set_bank_name "REO UK"
    set_header true

    def import_csv(csv)
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = get_columns(row, :description).join(" ")
        description = row[i(:tran_type)] if description.blank?
        amount = row[i(:debt_amount)].present? ? "-" + row[i(:debt_amount)] : row[i(:credit_amount)]
        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end
  end
end
