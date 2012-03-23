require 'spec_helper'
include Bucky

#TODO optomized the tests, I confess I didn't do any of that when writing them

describe Route do
  let (:route)       { Route.make }

  specify { route.should be_valid }

  context :route_days do
    specify { Route.make(:monday => false).should_not be_valid }
  end

  context :schedule do
    before do
      route.monday    = true
      route.wednesday = true
      route.friday    = true
      route.save
    end

    specify { route.schedule.should_not be_nil }
    specify { route.schedule.to_s.should == "Weekly on Mondays, Wednesdays, and Fridays" }
  end

  context :schedule_transaction do
    before do
      route.save
      route.sunday = true
    end

    specify { expect { route.save }.should change(RouteScheduleTransaction, :count).by(1) }
  end

  describe '#best_route' do
    it 'should just return the first one for now' do
      Route.default_route(route.distributor).should == route
    end
  end

  describe '#delivery_days' do
    before { route.friday = true }

    it 'should return any array of all the selected days' do
      route.delivery_days.should == [:monday, :friday]
    end
  end

  describe '.deleted_days' do
    before do
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { route.send(:deleted_days).should eq(Route::DAYS) }
  end

  describe '.deleted_day_numbers' do
    before do
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { route.send(:deleted_day_numbers).should eq([0,1,2,3,4,5,6]) }
  end

  describe 'when saving and triggering an update_schedule' do
    let(:order)     { double("order", :schedule_empty? => false, :save => true) }
    let(:route)     { Route.make }

    def stub_future_active_orders(route, orders)
      scope = double("scope")
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

  describe 'when saving and triggering an update_schedule (without mocking)' do
    before do
      @schedule_start_time = Time.now
      route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @customer = Fabricate(:customer, route: route, distributor: route.distributor)
      @account = @customer.account
      @box = Fabricate(:box, distributor: route.distributor)
      @order = Fabricate(:recurring_order, schedule: new_everyday_schedule(@schedule_start_time), account: @account, box: @box)
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

    context "when removing a day" do
      before do
        @day = :tuesday
        route.tuesday = false
        route.save
        @order.reload
        @monthly_order.reload
        @order_times.map{|d, order| order.reload}
      end

      it "should remove only the specified day from the order schedule" do
        @order.schedule.to_s.should_not match /#{@day.to_s}/i
        @monthly_order.schedule.to_s.should_not match /#{@day.to_s}/i

        (Route::DAYS - [@day]).each do |remaining_day|
          @order.schedule.to_s.should match /#{remaining_day.to_s}/i
          @monthly_order.schedule.to_s.should match /#{remaining_day.to_s}/i
          @monthly_order.schedule.to_s.should match /Monthly/i
        end
      end

      it "should remove only the specified day from the scheduled times" do
        @order_times[@day].schedule.recurrence_times.size.should eq(0)
        (Route::DAYS - [@day]).each do |remaining_day|
          @order_times[remaining_day].schedule.recurrence_times.first.should eq(@next_times[remaining_day])
        end
      end

      specify { @order.schedule.exception_times.should eq(@pause_range) }
      specify { @monthly_order.schedule.exception_times.should eq(@pause_range) }

      specify { @order.schedule.start_time.should eq(@schedule_start_time) }
      specify { @monthly_order.schedule.start_time.should eq(@schedule_start_time) }

      Route::DAYS.each do |day|
        specify { @order_times[day].schedule.start_time.should eq(@next_times[day]) }
        specify { @order_times[day].schedule.exception_times.should eq(@pause_range)}
      end
    end

    context "remove monday and friday" do
      before do
        route.update_attributes(monday: false, friday:false)
        @order.reload
        @monthly_order.reload
        @order_times.map{|d, order| order.reload}
      end

      specify { @order.schedule.to_s.should match /Weekly on Sundays, Tuesdays, Wednesdays, Thursdays, and Saturdays/ }
      specify { @order.should be_active }
      specify { @monthly_order.schedule.to_s.should match /Monthly.*Sunday.*Tuesday.*Wednesday.*Thursday.*Saturday/ }
      specify { @monthly_order.should be_active }

      (Route::DAYS - [:monday, :friday]).each do |day|
        specify { @order_times[day].schedule.recurrence_times.should_not be_empty }
        specify { @order_times[day].should be_active }
      end
      [:monday, :friday].each do |day|
        specify { @order_times[day].schedule.recurrence_times.should be_empty }
        specify { @order_times[day].should_not be_active }
      end

      specify { @order.schedule.exception_times.should eq(@pause_range) }
      specify { @order.schedule.start_time.should eq(@schedule_start_time) }
      specify { @monthly_order.schedule.exception_times.should eq(@pause_range) }
      specify { @monthly_order.schedule.start_time.should eq(@schedule_start_time) }

      Route::DAYS.each do |day|
        specify { @order_times[day].schedule.start_time.should eq(@next_times[day]) }
        specify { @order_times[day].schedule.exception_times.should eq(@pause_range)}
      end

      context "and then remove sunday, tuesday, wednesday, thursday, saturday and add monday" do
        before do
          route.update_attributes(sunday: false, monday: true, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false)
          @order.reload
          @monthly_order.reload
          @order_times.map{|d, order| order.reload}
        end

        specify { @order.should_not be_active }
        specify { @monthly_order.should_not be_active }
        Route::DAYS.each do |day|
          specify { @order_times[day].should_not be_active }
        end
      end
    end

    context "remove most days" do
      before do
        route.update_attributes(monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false)
        @order.reload
        @monthly_order.reload
        @order_times.map{|d, order| order.reload}
      end

      specify { @order.schedule.to_s.should match /Weekly on Sundays/ }
      specify { @order.should be_active }
      specify { @monthly_order.schedule.to_s.should match /Monthly on the 1st Sunday/ }
      specify { @monthly_order.should be_active }

      (Route::DAYS - [:sunday]).each do |day|
        specify { @order_times[day].schedule.recurrence_times.should be_empty }
        specify { @order_times[day].should_not be_active }
      end
      [:sunday].each do |day|
        specify { @order_times[day].schedule.recurrence_times.should_not be_empty }
        specify { @order_times[day].should be_active }
      end

      specify { @order.schedule.start_time.should eq(@schedule_start_time) }
      specify { @order.schedule.exception_times.should eq(@pause_range) }
      specify { @monthly_order.schedule.start_time.should eq(@schedule_start_time) }
      specify { @monthly_order.schedule.exception_times.should eq(@pause_range) }

      Route::DAYS.each do |day|
        specify { @order_times[day].schedule.start_time.should eq(@next_times[day]) }
        specify { @order_times[day].schedule.exception_times.should eq(@pause_range)}
      end
    end
  end
end

