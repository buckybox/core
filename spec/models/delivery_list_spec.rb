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

  describe '.collect_list' do
    before do
      time_travel_to Date.parse('2013-05-01')

      @order = Fabricate(:recurring_order, completed: true)
      @distributor = @order.distributor
      @order.schedule_rule.recur = "monthly"
      @start_date = @order.schedule_rule.start

      @today = Date.parse('2013-05-08')
      time_travel_to @today

      @distributor.generate_required_daily_lists_between(@start_date, @today)
    end

    it "is a delivery day today" do
      @today.should eq @order.schedule_rule.next_occurrence
    end

    it "works with the first week day" do
      delivery_date = @order.schedule_rule.next_occurrence
      delivery_list = DeliveryList.collect_list(@distributor, delivery_date)

      delivery_list.deliveries.should eq [@order]
    end

    it "works with the nth week day" do
      @order.schedule_rule.week = 2
      delivery_date = @order.schedule_rule.next_occurrence
      delivery_date.should_not be > @today

      delivery_list = DeliveryList.collect_list(@distributor, delivery_date)

      delivery_list.deliveries.should eq [@order]
    end

    after { back_to_the_present }
  end

  describe '.generate_list' do
    before do
      time_travel_to Date.current

      @distributor = Fabricate(:distributor)
      daily_orders(@distributor)

      @advance_days  = Distributor::DEFAULT_ADVANCED_DAYS
      @generate_date = Date.current + @advance_days
      time_travel_to Date.current + 1.day
    end

    after { back_to_the_present }

    specify { expect { DeliveryList.generate_list(@distributor, @generate_date) }.to change(@distributor.delivery_lists, :count).from(@advance_days).to(@advance_days + 1) }
    specify { expect { PackingList.generate_list(@distributor, @generate_date); DeliveryList.generate_list(@distributor, @generate_date) }.to change(@distributor.deliveries, :count).from(0).to(3) }

    context 'for the next week' do
      before do
        PackingList.generate_list(@distributor, @generate_date)
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

      specify { expect { delivery_list.reposition([@diff_route.id, delivery.id]) }.to raise_error(RuntimeError) }
    end

    context 'delivery ids must match' do
      before do
        @ids = [1, 2, 3]

        Delivery.stub_chain(:find, :route_id)
        Delivery.stub_chain(:find, :delivery_list, :date, :wday)
        delivery_list.stub_chain(:deliveries, :where, :select, :map).and_return(@ids)

        delivery_list.deliveries.stub_chain(:ordered, :find).and_return(delivery)
        delivery.stub(:reposition!).and_return(true)
      end

      specify { expect { delivery_list.reposition([2, 1, 3]) }.to_not raise_error(RuntimeError) }
      specify { expect { delivery_list.reposition([2, 5, 3]) }.to raise_error(RuntimeError) }
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
        expect { delivery_list.reposition(@new_ids)}.to change{delivery_list.deliveries.ordered.collect(&:id)}.to(@new_ids)
        delivery_list.reload.deliveries.ordered.collect(&:delivery_number).should eq([3,1,2])
      end

      it 'should update the delivery list for the next week' do
        Distributor.any_instance.stub(:generate_required_daily_lists) #TODO remove this hack to get around the constant after_save callbacks
        delivery_list.reposition(@new_ids)
        addresses = delivery_list.deliveries.ordered.collect(&:address)
        next_packing_list = PackingList.generate_list(distributor, delivery_list.date+1.week)
        next_delivery_list = DeliveryList.generate_list(distributor, delivery_list.date+1.week)
        Distributor.any_instance.unstub(:generate_required_daily_lists) #TODO remove this hack to get around the constant after_save callbacks

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
        order = Fabricate(:active_order, account: account, schedule_rule: new_single_schedule(date), box: box)
        order2 = Fabricate(:active_order, account: account2, schedule_rule: new_single_schedule(date), box: box)

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
  route ||= Fabricate(:route, distributor: distributor, schedule_rule: Fabricate(:schedule_rule, start: Date.current.yesterday))

  customer = Fabricate(:customer, distributor: distributor, route: route)
  account = Fabricate(:account, customer: customer)

  customer.address.delete

  if address
    address.customer = customer
    address.save!
  else
    address = Fabricate(:address, customer: customer)
  end

  customer.address = address

  Fabricate(:delivery, delivery_list: delivery_list, order: Fabricate(:recurring_order_everyday, account: account), route: route)
end
