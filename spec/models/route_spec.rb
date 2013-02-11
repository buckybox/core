require 'spec_helper'
include Bucky

describe Route do
  let(:route) { Fabricate(:route) }

  specify { route.should be_valid }

  context :schedule_transaction do
    before do
      route.save!
    end

    specify { 
      schedule_rule = route.schedule_rule
      schedule_rule.should_receive(:record_schedule_transaction)
      route.schedule_rule.sun = !route.schedule_rule.sun
      route.save!
    }
  end

  describe '#best_route' do
    before do
      @distributor = Fabricate(:distributor)
      @distributor.routes.stub(:first).and_return(route)
    end

    it 'should just return the first one for now' do
      Route.default_route(@distributor).should == route
    end
  end

  describe '.update_schedule' do
    before do
      @schedule_start_time = Time.now
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @customer = Fabricate(:customer, route: route, distributor: route.distributor)
      @account = @customer.account
      @box = Fabricate(:box, distributor: route.distributor)
      @order = Fabricate(:recurring_order, schedule: new_recurring_schedule(@schedule_start_time, Route::DAYS), account: @account, box: @box)
      route.schedule.to_s.should match(/Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/)
      @order.schedule.to_s.should match(/Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/)
      route.future_orders.should include(@order)

      # [0, 1, ...] === [:sunday, :monday, ..], kinda
      @monthly_order = Fabricate(:recurring_order, schedule: new_monthly_schedule(@schedule_start_time, [0,1,2,3,4,5,6]), account: @account, box: @box)

      @order_times = {}
      @next_times = {}
      @start_pause = 2.weeks.from_now.to_date
      @end_pause = 3.weeks.from_now.to_date
      @pause_range = (@start_pause..@end_pause).to_a.collect(&:beginning_of_day)

      @order.pause(@start_pause, @end_pause)
      @monthly_order.pause(@start_pause, @end_pause)

      Route::DAYS.each do |d|
        @next_times[d] = Time.next(d)
        @order_times[d] = Fabricate(:order, schedule: new_single_schedule(@next_times[d]), account: @account, box: @box)
        @order_times[d].pause(@start_pause, @end_pause)
      end
    end
  end

  describe 'when saving and triggering an update_schedule' do
    let(:order) { double('order', schedule_empty?: false, save: true) }
    let(:route) { Fabricate(:route) }

    def stub_future_active_orders(route, orders)
      scope = double('scope')
      Order.stub(:for_route_read_only).with(route).and_return(scope)
      scope.stub(:active).and_return(scope)
      scope.stub(:each).and_yield(*orders)
    end

    context "when removing a day" do
      it "should deactivate the specified day on active orders" do
        route.schedule_rule.wed = true
        route.save!
        route.schedule_rule.wed = false
        stub_future_active_orders(route, [order])
        order.should_receive(:deactivate_for_day!).with(3)

        route.save
      end
    end
  end

  context :schedule_rule do
    it "should create a schedule_rule" do
      route = Route.new
      route.schedule_rule.should_not == nil
    end
  end

end
