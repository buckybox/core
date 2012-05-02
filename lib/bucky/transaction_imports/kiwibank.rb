class Bucky::TransactionImports::Kiwibank
  TEST_FILE = File.new(File.join(Rails.root, "spec/support/test_upload_files/transaction_imports/kiwibank.csv"))
  
  COLUMNS = [:date, :description, :empty, :amount]

  attr_accessor :rows

  def import(file)
    
  end

  def import_csv(csv)
    transaction_rows = []
    CSV.parse(csv, headers: true) do |row|
      add_row(Row.new(*get_columns(row, :date, :description, :amount)))
    end

    rows
  end

  def add_row(row)
    @rows ||= []
    @rows << row
  end

  def valid?
    @rows.all?(&:valid?)
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
