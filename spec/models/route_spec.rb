require 'spec_helper'
include Bucky

describe Route do
  let (:route) { Fabricate.build(:route) }

  specify { route.should be_valid }

  context :schedule do
    before do
      route.tuesday  = false
      route.thursday = false
      route.saturday = false
      route.sunday   = false
      route.save
    end

    specify { route.schedule.should_not be_nil }
    specify { route.schedule.to_s.should == "Weekly on Mondays, Wednesdays, and Fridays" }
  end

  context :schedule_transaction do
    before do
      route.save
      route.sunday = false
    end

    specify { expect { route.save }.should change(RouteScheduleTransaction, :count).by(1) }
  end

  describe '#best_route' do
    before do
      @distributor = Fabricate.build(:distributor)
      @distributor.routes.stub(:first).and_return(route)
    end

    it 'should just return the first one for now' do
      Route.default_route(@distributor).should == route
    end
  end

  describe '#delivery_days' do
    before { route.friday = false }

    it 'should return any array of all the selected days' do
      route.delivery_days.should == [:sunday, :monday, :tuesday, :wednesday, :thursday, :saturday]
    end
  end

  describe '.deleted_days' do
    before do
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { route.send(:deleted_days).should eq(Bucky::Schedule::DAYS) }
  end

  describe '.deleted_day_numbers' do
    before do
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { route.send(:deleted_day_numbers).should eq([0,1,2,3,4,5,6]) }
  end

  describe '.update_schedule' do
    before do
      @schedule_start_time = Time.now
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @customer = Fabricate(:customer, route: route, distributor: route.distributor)
      @account = @customer.account
      @box = Fabricate(:box, distributor: route.distributor)
      @order = Fabricate(:recurring_order, schedule: new_recurring_schedule(@schedule_start_time, Route::DAYS), account: @account, box: @box)
      route.schedule.to_s.should match /Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/ 
      @order.schedule.to_s.should match /Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/ 
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
    let(:route) { Fabricate.build(:route) }

    def stub_future_active_orders(route, orders)
      scope = double('scope')
      Order.stub(:for_route_read_only).with(route).and_return(scope)
      scope.stub(:active).and_return(scope)
      scope.stub(:each).and_yield(*orders)
    end

    context "when removing a day" do
      it "should deactivate the specified day on active orders" do
        route.wednesday = true
        route.save!
        route.wednesday = false
        stub_future_active_orders(route, [order])
        order.should_receive(:deactivate_for_day!).with(3)

        route.save
      end
    end
  end
end

