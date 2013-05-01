require 'fast_spec_helper'
require 'csv'
require_model 'generator', sub_dir: 'sales_csv'
require_model 'order_generator', sub_dir: 'sales_csv'
required_constants %w(OrderRowGenerator)

describe SalesCsv::OrderGenerator do
  let(:empty_data)    { [] }
  let(:some_data)     { (1..10).to_a }
  let(:csv_row)       { double('csv_row') }
  let(:row_generator) { double('row_generator', new: csv_row) }

  describe '#generate' do
    after do
      order_generator = SalesCsv::OrderGenerator.new(@args, row_generator: row_generator)
      order_generator.generate.should == @expected_result
    end

    it 'generates a csv without data' do
      csv_row.stub(:generate) { empty_data }
      @args = []
      @expected_result = expected_csv_header
    end

    it 'generates a csv with data' do
      csv_row.stub(:generate) { some_data }
      @args = [ double('item1') ]
      @expected_result = expected_csv_header + "1,2,3,4,5,6,7,8,9,10\n"
    end
  end

  def expected_csv_header
    [
      'Delivery Route',
      'Delivery Sequence Number',
      'Delivery Pickup Point Name',
      'Order Number',
      'Package Number',
      'Delivery Date',
      'Customer Number',
      'Customer First Name',
      'Customer Last Name',
      'Customer Phone',
      'New Customer',
      'Delivery Address Line 1',
      'Delivery Address Line 2',
      'Delivery Address Suburb',
      'Delivery Address City',
      'Delivery Address Postcode',
      'Delivery Note',
      'Box Contents Short Description',
      'Box Type',
      'Box Likes',
      'Box Dislikes',
      'Box Extra Line Items',
      'Price',
      'Bucky Box Transaction Fee',
      'Total Price',
      'Customer Email',
      'Customer Special Preferences',
      'Package Status',
      'Delivery Status',
    ].to_csv
  end
end

