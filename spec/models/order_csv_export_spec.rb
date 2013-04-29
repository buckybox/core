require 'fast_spec_helper'
require_model 'csv_export'
require_model 'order_csv_export'
required_constants %w(DeliverySort OrderCsvGenerator)

describe OrderCsvExport do
  let(:expected_array)   { [1, 2, 3] }
  let(:orders)           { double('orders') }
  let(:distributor)      { double('distributor', orders_with_ids: orders) }
  let(:ids)              { double('ids') }
  let(:date)             { double('date', to_s: '2013-04-04') }
  let(:screen)           { double('screen', to_s: 'packages') }
  let(:csv_generator)    { double('csv_generator', generate: expected_array) }
  let(:valid_args)       { { distributor: distributor, ids: ids, date: date, screen: screen } }
  let(:order_csv_export) { OrderCsvExport.new(valid_args) }

  describe '#csv' do
    before do
      DeliverySort.stub(:by_dso)   { expected_array }
      OrderCsvGenerator.stub(:new) { csv_generator }

      @data, @file_args = order_csv_export.csv
    end

    it 'returns the data for a csv export' do
      @data.should == expected_array
    end

    it 'returns the arguments for a csv export' do
      type     = 'text/csv; charset=utf-8; header=present'
      filename = 'bucky-box-packages-export-2013-04-04.csv'
      @file_args.should == { type: type, filename: filename }
    end
  end
end
