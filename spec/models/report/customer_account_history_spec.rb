require_relative '../../../app/models/report/customer_account_history'

describe Report::CustomerAccountHistory do
  let(:customer)                 { double('customer') } 
  let(:customers)                { double('customers', ordered: [ customer ]) }
  let(:distributor)              { double('distributor', customers: customers) }
  let(:args)                     { { distributor: distributor, customers: customers } }

  describe '#name' do
    ['2013-08-04', '2012-07-12'].each do |date|
      context "when the date is #{date}" do
        it 'returns the name of the csv file to export' do
          args[:date] = date
          expected_result = "bucky-box-customer-account-balance-export-#{date}"
          customer_account_history = Report::CustomerAccountHistory.new(args)
          customer_account_history.name.should eq(expected_result)
        end
      end
    end
  end

  describe '#date' do
    before do
      args[:date] = '2013-04-23'
    end

    it 'returns the customers data in csv format' do
      customer_account_history = Report::CustomerAccountHistory.new(args)
      customer_account_history.data.should eq('')
    end
  end
end
