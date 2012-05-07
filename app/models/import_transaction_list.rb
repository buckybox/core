class ImportTransactionList < ActiveRecord::Base

  belongs_to :distributor
  has_many :import_transactions, autosave: true

  ACCOUNTS = [:kiwibank, :paypal]
  SOURCES = [:manual, :kiwibank_csv]

  def account
    ACCOUNTS[account_type]
  end

  def source
    SOURCES[source_type]
  end

  def load_rows(rows)
    rows.each do |row|
      import_transactions << ImportTransaction.new_from_row(row, distributor)
    end
    import_transactions
  end

end
