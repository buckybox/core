require_relative '../report'

class Report::CustomerAccountHistory

  NAME_PREFIX = 'bucky-box-customer-account-balance-export'

  def initialize(args = {})
    @distributor = args[:distributor]
    @date        = Date.parse(args[:date])
    @customers   = distributor.customers.ordered
  end

  def name
    "#{NAME_PREFIX}-#{Report::format_date(date)}"
  end

  def data
    CSV.generate do |csv|
      csv << csv_header
      customers.each { |customer| csv << csv_row(customer) }
    end
  end

private

  attr_reader :distributor
  attr_reader :date
  attr_reader :customers

  def csv_header
    [
      "Date",
      "Customer Number",
      "Customer First Name",
      "Customer Last Name",
      "Customer Email",
      "Customer Account Balance",
    ]
  end

  def csv_row(customer)
    [
      date.iso8601,
      customer.formated_number,
      customer.first_name,
      customer.last_name,
      customer.email,
      customer.balance_at(date),
    ]
  end

end

