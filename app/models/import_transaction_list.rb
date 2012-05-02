class ImportTransactionList < ActiveRecord::Base

  has_many :import_transactions

  ACCOUNTS = [:kiwibank, :paypal]
  SOURCES = [:manual, :kiwibank_csv]


  def account
    ACCOUNTS[account_type]
  end
  def source
    SOURCES[source_type]
  end
end
