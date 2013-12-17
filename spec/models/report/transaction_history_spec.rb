require_relative '../../../app/models/report/transaction_history'
require 'date'

describe Report::TransactionHistory do

  let(:customer) do
    double('customer',
      first_name: 'Joe',
      last_name:  'Dalton',
      number:     9,
      email:      'email@example.com',
      discount:   0.0,
      labels:     'tag',
    )
  end
  let(:transaction) do
    double('transaction',
      created_at:    Date.parse('2013-07-06'),
      display_time:  Date.parse('2013-07-07'),
      transactionable_type: 'Payment',
      amount:        3,
      description:   'Desc',
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
      expected_result = "07/Jul/2013,06/Jul/2013,3,Payment,Desc,9,Joe,Dalton,email@example.com,0.0,tag\n"
      expect(transaction_history.data.lines.last).to eq(expected_result)
    end
  end

end
