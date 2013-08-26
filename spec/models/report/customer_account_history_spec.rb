require_relative '../../../app/models/report/customer_account_history'

describe Report::CustomerAccountHistory do

  let(:customer) do
    double('customer',
      formated_number:  '012',
      first_name:       'First',
      last_name:        'Last',
      email:            'text@example.com',
      balance_at:       10,
    )
  end
  let(:customers)   { double('customers', ordered: [ customer ]) }
  let(:distributor) { double('distributor', customers: customers) }
  let(:args)        { { distributor: distributor, customers: customers, date: '2013-04-23' } }

  describe '#name' do
    it 'returns the name of the csv file to export' do
      customer_account_history = Report::CustomerAccountHistory.new(args)
      expected_result = "bucky-box-customer-account-balance-export-2013-04-23"
      customer_account_history.name.should eq(expected_result)
    end
  end

  describe '#data' do
    it 'returns the customers data in csv format' do
      customer_account_history = Report::CustomerAccountHistory.new(args)
      expected_result = "Date,Customer Number,Customer First Name,Customer Last Name,Customer Email,"
      expected_result += "Customer Account Balance\n2013-04-23,012,First,Last,text@example.com,10\n"
      customer_account_history.data.should eq(expected_result)
    end
  end

end
