require 'spec_helper'
include Bucky

describe DeliveryService do
  let(:delivery_service) { Fabricate(:delivery_service) }

  specify { delivery_service.should be_valid }

  context :schedule_transaction do
    before do
      delivery_service.save!
    end

    specify { 
      schedule_rule = delivery_service.schedule_rule
      schedule_rule.should_receive(:record_schedule_transaction)
      delivery_service.schedule_rule.sun = !delivery_service.schedule_rule.sun
      delivery_service.save!
    }
  end

  describe '#best_delivery_service' do
    before do
      @distributor = Fabricate(:distributor)
      @distributor.delivery_services.stub(:first).and_return(delivery_service)
    end

    it 'should just return the first one for now' do
      DeliveryService.default_delivery_service(@distributor).should == delivery_service
    end
  end

  describe '.update_schedule' do
    before do
      @schedule_start_time = Time.now
      delivery_service.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @customer = Fabricate(:customer, delivery_service: delivery_service, distributor: delivery_service.distributor)
      @account = @customer.account
      @box = Fabricate(:box, distributor: delivery_service.distributor)
      @order = Fabricate(:recurring_order, schedule: new_recurring_schedule(@schedule_start_time, DeliveryService::DAYS), account: @account, box: @box)
      delivery_service.schedule.to_s.should match(/Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/)
      @order.schedule.to_s.should match(/Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/)
      delivery_service.future_orders.should include(@order)

      # [0, 1, ...] === [:sunday, :monday, ..], kinda
      @monthly_order = Fabricate(:recurring_order, schedule: new_monthly_schedule(@schedule_start_time, [0,1,2,3,4,5,6]), account: @account, box: @box)

      @order_times = {}
      @next_times = {}
      @start_pause = 2.weeks.from_now.to_date
      @end_pause = 3.weeks.from_now.to_date
      @pause_range = (@start_pause..@end_pause).to_a.collect(&:beginning_of_day)

      @order.pause(@start_pause, @end_pause)
      @monthly_order.pause(@start_pause, @end_pause)

      DeliveryService::DAYS.each do |d|
        @next_times[d] = Time.next(d)
        @order_times[d] = Fabricate(:order, schedule: new_single_schedule(@next_times[d]), account: @account, box: @box)
        @order_times[d].pause(@start_pause, @end_pause)
      end
    end
  end

  describe 'when saving and triggering an update_schedule' do
    let(:order) { double('order', schedule_empty?: false, save: true) }
    let(:delivery_service) { Fabricate(:delivery_service) }

    def stub_future_active_orders(delivery_service, orders)
      scope = double('scope')
      Order.stub(:for_delivery_service_read_only).with(delivery_service).and_return(scope)
      scope.stub(:active).and_return(scope)
      scope.stub(:each).and_yield(*orders)
    end

    context "when removing a day" do
      it "should deactivate the specified day on active orders" do
        delivery_service.schedule_rule.wed = true
        delivery_service.save!
        delivery_service.schedule_rule.wed = false
        stub_future_active_orders(delivery_service, [order])
        order.should_receive(:deactivate_for_day!).with(3)

        delivery_service.save
      end
    end
  end

  context :schedule_rule do
    it "should create a schedule_rule" do
      delivery_service = DeliveryService.new
      delivery_service.schedule_rule.should_not == nil
    end
  end

end
