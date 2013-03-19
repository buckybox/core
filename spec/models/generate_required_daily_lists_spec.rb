require 'fast_spec_helper'
require 'date'
require_model 'generate_required_daily_lists'
required_constants %w(Distributor PackingList DeliveryList)

describe GenerateRequiredDailyLists do
  describe '#generate' do
    let(:distributor)            { Distributor.new }
    let(:window_start_from)      { Date.new(2012, 11, 8) }
    let(:window_end_at)          { Date.new(2012, 11, 9) }
    let(:returned_packing_list)  { double('returned_packing_list') }
    let(:returned_delivery_list) { double('returned_delivery_list') }
    let(:delivery_list)          { double('delivery_list', destroy: true) }
    let(:delivery_lists)         { double('delivery_lists', find_by_date: delivery_list) }

    let(:packing_list) do
      double('packing_list',
        date: Date.new(2012, 11, 8),
        destroy: true
      )
    end

    let(:packing_lists) do
      double('packing_lists',
        last:          nil,
        find_by_date:  packing_list,
      )
    end

    let(:generate_required_daily_lists) do
      GenerateRequiredDailyLists.new(
        distributor:        self,
        window_start_from:  window_start_from,
        window_end_at:      window_end_at,
        packing_lists:      packing_lists,
        delivery_lists:     delivery_lists,
      )
    end

    before do
      distributor.stub(
        window_start_from:  window_start_from,
        window_end_at:      window_end_at,
        packing_lists:      packing_lists,
        delivery_lists:     delivery_lists,
      )

      returned_packing_list.stub(:date).and_return(Date.new(2012, 11, 8), Date.new(2012, 11, 9))
      returned_delivery_list.stub(:date).and_return(Date.new(2012, 11, 8), Date.new(2012, 11, 9))

      PackingList.stub(:generate_list)  { returned_packing_list }
      DeliveryList.stub(:generate_list) { returned_delivery_list }
    end

    subject { generate_required_daily_lists.generate }

    it 'works' do
      should be_true
    end

    it 'has a start date equal to the end date' do
      window_start_from = Date.new(2012, 11, 9)
      should be_true
    end

    context 'when there is a packing list and it has a date that is after the end date' do
      before do
        packing_lists.stub(:last) { packing_list }
        packing_list.stub(:date)  { Date.new(2012, 11, 10) }
      end

      it 'works' do
        should be_true
      end

      it 'could not find packing list' do
        packing_lists.stub(:find_by_date) { nil }
        should be_true
      end

      it 'could not destroy a packing list' do
        packing_list.stub(:destroy) { false }
        should be_false
      end

      it 'could not find a delivery list' do
        delivery_lists.stub(:find_by_date) { nil }
        should be_true
      end

      it 'could not destroy a delivery list' do
        delivery_list.stub(:destroy) { false }
        should be_false
      end
    end

    context 'when there is no packing list or it is less than or equal to the end date' do
      before do
        packing_lists.stub(:last) { packing_list }
        packing_list.stub(:date)  { Date.new(2012, 11, 8) }
      end

      it 'works' do
        should be_true
      end

      it 'has a packing list date that does not equal the requested date' do
        returned_packing_list.stub(:date) { Date.new(2012, 11, 13) }
        should be_false
      end

      it 'has a packing list date that does not equal the requested date' do
        returned_delivery_list.stub(:date) { Date.new(2012, 11, 13) }
        should be_false
      end
    end
  end
end
