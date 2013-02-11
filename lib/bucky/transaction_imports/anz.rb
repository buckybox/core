module Bucky::TransactionImports
  class Anz < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/anz.csv"))
    
    set_columns :tran_type, :name, :ref1, :ref2, :ref3, :amount, :date
    set_bank_name "ANZ"
    set_header false

    def import_csv(csv)
      index = 1
      CSV.parse(csv, headers: false, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = get_columns(row, :name, :ref1, :ref2, :ref3).join(" ")
        description = row[i(:tran_type)] if description.blank? # some transactions don't have name, ref1-3, but description can't be blank, so use tran_type
        amount = row[i(:amount)]

        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end
  end
end
