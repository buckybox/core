module Bucky::TransactionImports
  class Paypal < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/paypal.csv"))
    
    set_columns :date, :time, :time_zone, :name, :type, :status, :currency, :gross, :fee, :net, :from_email_address, :to_email_address, :transaction_id
    set_bank_name "Paypal"
    set_header true

    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: true, skip_blanks: true) do |row|
        date = row[i(:date)]
        name_and_email = [row[i(:name)], row[i(:from_email_address)]].join(" ")
        type = row[i(:type)]
        description = [name_and_email, type].reject(&:blank?).first
        amount = row[i(:gross)]
        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end
  end
end
