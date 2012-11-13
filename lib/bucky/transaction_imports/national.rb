module Bucky::TransactionImports
  class National < CsvImport
    TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/national.csv"))
    
    set_columns :tran_type, :name, :ref1, :ref2, :ref3, :amount, :date
    set_bank_name "National Bank"
    set_header false

    def import_csv(csv)
      transaction_rows = []
      index = 1
      CSV.parse(csv, headers: false, skip_blanks: true) do |row|
        date = row[i(:date)]
        description = concat(row, :name, :ref1, :ref2, :ref3)
        if description.blank?
          description = row[i(:tran_type)]
        end
        amount = row[i(:amount)]

        add_row(date, description, amount, index, raw_data(row), self)
        index += 1
      end

      rows
    end
  end
end
