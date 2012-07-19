require 'spec_helper'

describe DeliveryList do
  let(:distributor) { Fabricate.build(:distributor) }
  let(:route) { Fabricate.build(:route) }
  let(:delivery_list) { Fabricate.build(:delivery_list, distributor: distributor) }
  let(:delivery) { Fabricate.build(:delivery, delivery_list: delivery_list) }

  specify { delivery_list.should be_valid }

  def delivery_auto_delivering(result = true)
    delivery = mock_model(Delivery)
    Delivery.should_receive(:auto_deliver).with(delivery).and_return(result)
    return delivery
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

      @advance_days  = Distributor::DEFAULT_ADVANCED_DAYS
      @generate_date = Date.current + @advance_days.days

      time_travel_to @generate_date

      PackingList.generate_list(@distributor, @generate_date)
    end

    after { back_to_the_present }

    specify { expect { DeliveryList.generate_list(@distributor, @generate_date) }.should change(@distributor.delivery_lists, :count).from(@advance_days).to(@advance_days + 1) }
    specify { expect { DeliveryList.generate_list(@distributor, @generate_date) }.should change(@distributor.deliveries, :count).from(0).to(3) }

    context 'for the next week' do
      before do
        @dl1 = DeliveryList.generate_list(@distributor, @generate_date)
        PackingList.generate_list(@distributor, @generate_date + 1.week)
        @dl2 = DeliveryList.generate_list(@distributor, @generate_date + 1.week)
      end

      specify { @dl2.deliveries.map{|d| "#{d.customer.number}/#{d.position}"}.should == @dl1.deliveries.map{|d| "#{d.customer.number}/#{d.position}"} }

      context 'and the week after that' do
        before do
          PackingList.generate_list(@distributor, @generate_date + 2.week)
          @dl3 = DeliveryList.generate_list(@distributor, @generate_date + 2.week)
        end

        specify { @dl3.deliveries.map{|d| "#{d.customer.number}/#{d.position}"}.should == @dl2.deliveries.map{|d| "#{d.customer.number}/#{d.position}"} }
      end
    end

    after { back_to_the_present }
  end

  describe '#all_finished?' do
    before { delivery_list.save }

    context 'no deliveries are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: delivery_list)
        Fabricate(:delivery, status: 'delivered', delivery_list: delivery_list)
      end

      specify { delivery_list.all_finished?.should be_true }
    end

    context 'has deliveries that are pending' do
      before do
        Fabricate(:delivery, status: 'delivered', delivery_list: delivery_list)
        Fabricate(:delivery, status: 'pending', delivery_list: delivery_list)
      end

      specify { delivery_list.all_finished?.should_not be_true }
    end
  end

  describe '#reposition' do
    context 'makes sure the deliveries are from the same route' do
      before do
        delivery_list.save
        delivery.save
        @diff_route = Fabricate(:delivery, delivery_list: delivery_list)
        delivery_list.stub(:delivery_ids).and_return([delivery, @diff_route])
      end

      specify { expect { delivery_list.reposition([@diff_route.id, delivery.id]) }.should raise_error(RuntimeError) }
    end

    context 'delivery ids must match' do
      before do
        @ids = [1, 2, 3]

        Delivery.stub_chain(:find, :route_id)
        delivery_list.stub_chain(:deliveries, :where, :map).and_return(@ids)

        delivery_list.deliveries.stub(:find).and_return(delivery)
        delivery.stub(:reposition!).and_return(true)
      end

      specify { expect { delivery_list.reposition([2, 1, 3]) }.should_not raise_error(RuntimeError) }
      specify { expect { delivery_list.reposition([2, 5, 3]) }.should raise_error(RuntimeError) }
    end

    context 'should update delivery list positions' do
      before do
        delivery_list.save
        d1 = Fabricate(:delivery, delivery_list: delivery_list)
        d2 = Fabricate(:delivery, delivery_list: delivery_list, route: d1.route)
        d3 = Fabricate(:delivery, delivery_list: delivery_list, route: d1.route)
        @ids = delivery_list.delivery_ids
        @new_ids = @ids.shuffle
      end

      specify { expect { delivery_list.reposition(@new_ids) }.should change(delivery_list, :delivery_ids).to(@new_ids) }
    end
  end
end
