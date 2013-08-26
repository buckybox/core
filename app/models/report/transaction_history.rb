require 'date'
require 'csv'
require_relative '../report'

class Report::TransactionHistory

  NAME_PREFIX = 'bucky-box-transaction-history-export'
  DATE_FORMAT = '%d/%b/%Y'

  def initialize(args = {})
    @distributor  = args[:distributor]
    @from         = Date.parse(args[:from])
    @to           = Date.parse(args[:to])
    @transactions = distributor.transactions_for_export(from, to)
  end

  def name
    "#{NAME_PREFIX}-#{Report::format_date(from)}-to-#{Report::format_date(to)}"
  end

  def data
    CSV.generate do |csv|
      csv << csv_header
      transactions.each { |transaction| csv << csv_row(transaction) }
    end
  end

private

  attr_reader :distributor
  attr_reader :from
  attr_reader :to
  attr_reader :transactions

  def csv_header
    [
      "Date Transaction Occurred",
      "Date Transaction Processed",
      "Amount",
      "Description",
      "Customer Name",
      "Customer Number",
      "Customer Email",
      "Customer City",
      "Customer Suburb",
      "Customer Tags",
      "Discount",
    ]
  end

  def csv_row(transaction)
    row = add_transaction_data(transaction)
    row += add_customer_data(transaction)
  end

  def add_transaction_data(transaction)
    [
      transaction.created_at.strftime(DATE_FORMAT),
      transaction.display_time.strftime(DATE_FORMAT),
      transaction.amount,
      transaction.description,
    ]
  end

  def add_customer_data(transaction)
    customer = transaction_customer(transaction)
    address  = customer.address
    [
      customer.name,
      customer.number,
      customer.email,
      address.city,
      address.suburb,
      customer_tags(customer),
      customer.discount,
    ]
  end

  def transaction_customer(transaction)
    transaction.customer
  end

  def customer_tags(customer)
    customer.tags.map { |t| "\"#{t.name}\"" }.join(", ")
  end

end
