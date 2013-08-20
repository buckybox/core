require_relative '../../../app/models/report/transaction_history'
require 'date'

describe Report::TransactionHistory do

  let(:address) do
    double('address',
      city:    'City',
      suburb:  'Suburb',
    )
  end
  let(:tag) { double('tag', name: 'Tag') }
  let(:customer) do
    double('customer',
      name:      'Name',
      number:    9,
      email:     'email@example.com',
      discount:  0.0,
      address:   address,
      tags:      [ tag ],
    )
  end
  let(:transaction) do
    double('transaction',
      created_at:    Date.parse('2013-07-06'),
      display_time:  Date.parse('2013-07-07'),
      amount:        3,
      description:   'Manual',
      customer:      customer,
    )
  end
  let(:transactions) { [ transaction ] }
  let(:distributor) { double('distributor', transactions_for_export: transactions) }
  let(:args)        { { distributor: distributor, from: '2013-08-04', to: '2013-08-05' } }

  describe '#name' do
    it 'returns the name of the csv file to export' do
      transaction_history = Report::TransactionHistory.new(args)
      expected_result = "bucky-box-transaction-history-export-2013-08-04-to-2013-08-05"
      expect(transaction_history.name).to eq(expected_result)
    end
  end

  describe '#data' do
    it 'returns the customers data in csv format' do
      transaction_history = Report::TransactionHistory.new(args)
      expected_result = "Date Transaction Occurred,Date Transaction Processed,Amount,Description,Customer Name,"
      expected_result += "Customer Number,Customer Email,Customer City,Customer Suburb,Customer Tags,Discount\n"
      expected_result += "06/Jul/2013,07/Jul/2013,3,Manual,Name,9,email@example.com,City,Suburb,\"\"\"Tag\"\"\",0.0\n"
      expect(transaction_history.data).to eq(expected_result)
    end
  end

end
