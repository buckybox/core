require 'spec_helper'

describe DeliveryList do
  let(:fabricated_distributor) { Fabricate.build(:distributor) }
  let(:fabricated_route) { Fabricate.build(:route) }
  let(:fabricated_delivery_list) { Fabricate.build(:delivery_list, :distributor => fabricated_distributor) }
  let(:delivery_list) { DeliveryList.make }

  specify { delivery_list.should be_valid }

  def delivery_auto_delivering(result = true)
    delivery = mock_model(Delivery)
    Delivery.should_receive(:auto_deliver).with(delivery).and_return(result)
    delivery
  end

  describe 'when marking all as auto delivered' do
    it "returns true if there are no deliveries" do
      delivery_list.mark_all_as_auto_delivered.should be_true
    end

    it "returns true if all deliveries return true" do
      delivery_list.deliveries << delivery_auto_delivering
      delivery_list.deliveries << delivery_auto_delivering

      delivery_list.mark_all_as_auto_delivered.should be_true
    end

    it "returns false if one delivery returns false" do
      delivery_list.deliveries << delivery_auto_delivering
      delivery_list.deliveries << delivery_auto_delivering(false)
      delivery_list.deliveries << delivery_auto_delivering

      delivery_list.mark_all_as_auto_delivered.should be_false
    end
  end

  describe '.collect_lists' do
    before do
      time_travel_to Date.parse('2012-01-23')

      @distributor = Fabricate(:distributor)
      box = Fabricate(:box, distributor: @distributor)
      3.times { Fabricate(:recurring_order, completed: true, box: box) }

      time_travel_to Date.parse('2012-01-30')

      ((Date.current - 1.week)..Date.current).each { |date| DeliveryList.generate_list(@distributor, date) }
    end

    specify { DeliveryList.collect_lists(@distributor, (Date.current - 1.week), (Date.current + 1.week)).should be_kind_of(Array) }

    after { back_to_the_present }
  end

  describe '.generate_list' do
    before do
      time_travel_to Date.current

      @distributor = Fabricate(:distributor)
      daily_orders(@distributor)

      @advance_days = Distributor::DEFAULT_ADVANCED_DAYS
      @generate_date = Date.current + @advance_days.days

      time_travel_to @generate_date

      PackingList.generate_list(@distributor, @generate_date)
    end

    specify { expect { DeliveryList.generate_list(@distributor, @generate_date) }.should change(@distributor.delivery_lists, :count).from(@advance_days).to(@advance_days + 1) }
    specify { expect { DeliveryList.generate_list(@distributor, @generate_date) }.should change(@distributor.deliveries, :count).from(0).to(3) }

    after { back_to_the_present }
  end

  describe '#all_finished?' do
    context 'no deliveries are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: fabricated_delivery_list)
        Fabricate(:delivery, status: 'delivered', delivery_list: fabricated_delivery_list)
      end

      specify { fabricated_delivery_list.all_finished?.should be_true }
    end

    context 'has deliveries that are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: fabricated_delivery_list)
        Fabricate(:delivery, status: 'pending', delivery_list: fabricated_delivery_list)
      end

      specify { fabricated_delivery_list.all_finished?.should_not be_true }
    end
  end
end
