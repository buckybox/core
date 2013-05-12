require 'fast_spec_helper'
require_model 'exporter', sub_dir: 'sales_csv'
require_model 'order_exporter', sub_dir: 'sales_csv'
required_constants %w(DeliverySort OrderGenerator)

describe SalesCsv::OrderExporter do
  let(:expected_array) { [1, 2, 3] }
  let(:expected_hash)  { { items: expected_array } }
  let(:orders)         { double('orders') }
  let(:list)           { double('list', ordered_packages: orders, ordered_deliveries: orders) }
  let(:distributor)    { double('distributor', packing_list_by_date: list, delivery_list_by_date: list) }
  let(:ids)            { double('ids', is_a?: Integer) }
  let(:date)           { double('date', to_s: '2013-04-04') }
  let(:csv_generator)  { double('csv_generator', generate: expected_array) }
  let(:generator)      { double('generator', new: csv_generator) }
  let(:sorter)         { double('sorter', grouped_by_boxes: expected_hash, by_dso: expected_array) }
  let(:valid_args)     { { distributor: distributor, ids: ids, date: date, screen: screen, sorter: sorter, generator: generator } }
  let(:order_exporter) { SalesCsv::OrderExporter.new(valid_args) }

  context 'from the packing screen' do
    let(:screen) { double('screen', to_s: 'packing') }

    describe '#csv' do
      before do
        @data, @file_args = order_exporter.csv
      end

      it 'returns the data for a csv export' do
        @data.should == expected_array
      end

      it 'returns the arguments for a csv export' do
        type     = 'text/csv; charset=utf-8; header=present'
        filename = 'bucky-box-packing-export-2013-04-04.csv'
        @file_args.should == { type: type, filename: filename }
      end
    end
  end

  context 'from the delivery screen' do
    let(:screen) { double('screen', to_s: 'delivery') }

    describe '#csv' do
      before do
        @data, @file_args = order_exporter.csv
      end

      it 'returns the data for a csv export' do
        @data.should == expected_array
      end

      it 'returns the arguments for a csv export' do
        type     = 'text/csv; charset=utf-8; header=present'
        filename = 'bucky-box-delivery-export-2013-04-04.csv'
        @file_args.should == { type: type, filename: filename }
      end
    end
  end
end
