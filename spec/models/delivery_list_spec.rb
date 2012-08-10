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
    before do
      @deliveries = []
      delivery_list.stub_chain(:deliveries, :ordered).and_return(@deliveries)
    end

    it 'returns true if there are no deliveries' do
      delivery_list.mark_all_as_auto_delivered.should be_true
    end

    it 'returns true if all deliveries return true' do
      @deliveries << delivery_auto_delivering
      @deliveries << delivery_auto_delivering

      delivery_list.mark_all_as_auto_delivered.should be_true
    end

    it 'returns false if one delivery returns false' do
      @deliveries << delivery_auto_delivering
      @deliveries << delivery_auto_delivering(false)
      @deliveries << delivery_auto_delivering

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

      specify { @dl2.deliveries.ordered.map{|d| "#{d.customer.number}/#{d.position}"}.should == @dl1.deliveries.ordered.map{|d| "#{d.customer.number}/#{d.position}"} }

      context 'and the week after that' do
        before do
          PackingList.generate_list(@distributor, @generate_date + 2.week)
          @dl3 = DeliveryList.generate_list(@distributor, @generate_date + 2.week)
        end

        specify { @dl3.deliveries.ordered.map{|d| "#{d.customer.number}/#{d.position}"}.should == @dl2.deliveries.ordered.map{|d| "#{d.customer.number}/#{d.position}"} }
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
        Delivery.stub_chain(:find, :delivery_list, :date, :wday)
        delivery_list.stub_chain(:deliveries, :ordered, :where, :map).and_return(@ids)

        delivery_list.deliveries.stub_chain(:ordered, :find).and_return(delivery)
        delivery.stub(:reposition!).and_return(true)
      end

      specify { expect { delivery_list.reposition([2, 1, 3]) }.should_not raise_error(RuntimeError) }
      specify { expect { delivery_list.reposition([2, 5, 3]) }.should raise_error(RuntimeError) }
    end

    context 'should update delivery list positions' do
      before do
        delivery_list.save
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        d1 = fab_delivery(delivery_list, distributor)
        @route = d1.route
        d2 = fab_delivery(delivery_list, distributor, @route)
        d3 = fab_delivery(delivery_list, distributor, @route)
        @ids = delivery_list.reload.deliveries.ordered.collect(&:id)
        @new_ids = [@ids.last, @ids.first, @ids[1]]
      end

      it 'should change delivery order' do
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        expect { delivery_list.reposition(@new_ids)}.should change{delivery_list.deliveries.ordered.collect(&:id)}.to(@new_ids)
        delivery_list.reload.deliveries.ordered.collect(&:delivery_number).should eq([3,1,2])
      end

      it 'should update the delivery list for the next week' do
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        delivery_list.reposition(@new_ids)
        addresses = delivery_list.deliveries.ordered.collect(&:address)
        PackingList.generate_list(distributor, delivery_list.date+1.week)
        next_delivery_list = DeliveryList.generate_list(distributor, delivery_list.date+1.week)

        next_delivery_list.deliveries.ordered.collect(&:address).should eq(addresses)
        next_delivery_list.deliveries.ordered.collect(&:delivery_number).should eq([1,2,3])
      end

      it 'should put new deliveries at the top of the list' do
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        date = delivery_list.date
        delivery_list.reposition(@new_ids)
        addresses = delivery_list.deliveries.ordered.collect(&:address)
        
        box = Fabricate(:box, distributor: distributor)
        account = Fabricate(:account, customer: Fabricate(:customer, distributor: distributor, route: @route))
        account2 = Fabricate(:account, customer: Fabricate(:customer, distributor: distributor, route: @route))
        order = Fabricate(:active_order, account: account, schedule: new_single_schedule(date.to_time), box: box)
        order2 = Fabricate(:active_order, account: account2, schedule: new_single_schedule(date.to_time), box: box)

        PackingList.generate_list(distributor, date)
        next_delivery_list = DeliveryList.generate_list(distributor, date)

        next_delivery_list.deliveries.ordered.collect(&:address).should eq([account2.address, account.address]+addresses)
        next_delivery_list.deliveries.ordered.collect(&:delivery_number).should eq([4,5,3,1,2])
      end
    end

    context 'with duplicate or similar addresses' do
      before do
        delivery_list.save
        route = Fabricate(:route, distributor: distributor)
        @d1 = fab_delivery(delivery_list, distributor, route)
        @d2 = fab_delivery(delivery_list, distributor, route)
        @d3 = fab_delivery(delivery_list, distributor, route)
        
        d1_address = @d1.order.address
        address = Fabricate.build(:address, address_1: d1_address.address_1, address_2: d1_address.address_2, suburb: d1_address.suburb, city: d1_address.city, delivery_note: "Im different")
        @d4 = fab_delivery(delivery_list, distributor, route, address)

        @ids = [@d1.id, @d2.id, @d3.id, @d4.id]
      end

      it 'should order deliveries by default to be in order of creation' do
        delivery_list.deliveries.ordered.collect(&:id).should eq(@ids)
      end

      it 'should keep similiar addresses together' do
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        delivery_list.reposition(@ids)
        delivery_list.deliveries.ordered.collect(&:id).should eq([@d1.id, @d4.id, @d2.id, @d3.id])
      end

      it 'should give similiar addresses the same delivery number' do
        DeliveryList.any_instance.stub(:archived?).and_return(false)
        delivery_list.reposition(@ids)
        delivery_list.deliveries.ordered.collect(&:delivery_number).should eq([1, 1, 2, 3])
      end
    end
  end
end

def fab_delivery(delivery_list, distributor, route=nil, address=nil)
  route ||= Fabricate(:route, distributor: distributor)
  address ||= Fabricate.build(:address)
  account = Fabricate.build(:account)

  customer = Fabricate(:customer_without_after_create, distributor: distributor, route: route)
  address.customer = customer
  address.save!
  account.customer = customer
  account.save!

  Fabricate(:delivery, delivery_list: delivery_list, order: Fabricate(:recurring_order_everyday, account: account), route: route)
end
