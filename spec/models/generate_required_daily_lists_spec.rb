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

      allow(returned_packing_list).to receive(:date).and_return(Date.new(2012, 11, 8), Date.new(2012, 11, 9))
      allow(returned_delivery_list).to receive(:date).and_return(Date.new(2012, 11, 8), Date.new(2012, 11, 9))

      allow(PackingList).to receive(:generate_list)  { returned_packing_list }
      allow(DeliveryList).to receive(:generate_list) { returned_delivery_list }
    end

    subject { generate_required_daily_lists.generate }

    it 'works' do
      is_expected.to be true
    end

    it 'has a start date equal to the end date' do
      window_start_from = Date.new(2012, 11, 9)
      is_expected.to be true
    end

    context 'when there is a packing list and it has a date that is after the end date' do
      before do
        allow(packing_lists).to receive(:last) { packing_list }
        allow(packing_list).to receive(:date)  { Date.new(2012, 11, 10) }
      end

      it 'works' do
        is_expected.to be true
      end

      it 'could not find packing list' do
        allow(packing_lists).to receive(:find_by_date) { nil }
        is_expected.to be true
      end

      it 'could not destroy a packing list' do
        allow(packing_list).to receive(:destroy) { false }
        is_expected.to be false
      end

      it 'could not find a delivery list' do
        allow(delivery_lists).to receive(:find_by_date) { nil }
        is_expected.to be true
      end

      it 'could not destroy a delivery list' do
        allow(delivery_list).to receive(:destroy) { false }
        is_expected.to be false
      end
    end
  end
end
