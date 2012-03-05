require 'spec_helper'
include IceCube

describe Route do
  before { @route = Fabricate(:route) }

  specify { @route.should be_valid }

  context :route_days do
    specify { Fabricate.build(:route, :monday => false).should_not be_valid }
  end

  context :schedule do
    before do
      @route.monday    = true
      @route.wednesday = true
      @route.friday    = true
      @route.save
    end

    specify { @route.schedule.should_not be_nil }
    specify { @route.schedule.to_s.should == "Weekly on Mondays, Wednesdays, and Fridays" }
  end

  context :schedule_transaction do
    before { @route.sunday = true }
    specify { expect { @route.save }.should change(RouteScheduleTransaction, :count).by(1) }
  end

  describe '#best_route' do
    it 'should just return the first one for now' do
      Route.default_route(@route.distributor).should == @route
    end
  end

  describe '#delivery_days' do
    before { @route.friday = true }
    it 'should return any array of all the selected days' do
      @route.delivery_days.should == [:monday, :friday]
    end
  end

  describe '.deleted_days' do
    before do
      @route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { @route.send(:deleted_days).should eq(Route::DAYS) }
  end

  describe '.deleted_day_numbers' do
    before do
      @route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @route.attributes = {monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false, sunday: false}
    end
    specify { @route.send(:deleted_day_numbers).should eq([0,1,2,3,4,5,6]) }
  end
  
  describe '.update_schedule' do
    before do
      @route.update_attributes(monday: true, tuesday: true, wednesday: true, thursday: true, friday: true, saturday: true, sunday: true)
      @customer = Fabricate(:customer, route: @route, distributor: @route.distributor)
      @account = @customer.account
      @box = Fabricate(:box, distributor: @route.distributor)
      @order = Fabricate(:recurring_order, schedule: new_everyday_schedule, account: @account, box: @box)
      @route.schedule.to_s.should match /Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/ 
      @order.schedule.to_s.should match /Weekly on Sundays, Mondays, Tuesdays, Wednesdays, Thursdays, Fridays, and Saturdays/ 
      @route.future_orders.should include(@order)
      
      @order_times = {}
      @next_times = {}
      Route::DAYS.each do |d|
        @next_times[d] = Time.next(d)
        @order_times[d] = Fabricate(:order, schedule: new_single_schedule(@next_times[d]), account: @account, box: @box)
      end
    end
    
    Route::DAYS.each do |day|
      context "remove_#{day.to_s}" do
        before do
          @route.send("#{day.to_s}=", false)
          @route.save
          @order.reload
          @order_times.map{|d, order| order.reload}
        end
        it "should remove only #{day} from the order schedule" do
          @order.schedule.to_s.should_not match /#{day.to_s}/i 
          (Route::DAYS - [day]).each do |remaining_day|
            @order.schedule.to_s.should match /#{remaining_day.to_s}/i
          end
        end

        it "should remove #{day} from the scheduled times" do
          @order_times[day].schedule.recurrence_times.size.should eq(0)
          (Route::DAYS - [day]).each do |remaining_day|
            @order_times[remaining_day].schedule.recurrence_times.first.should eq(@next_times[remaining_day])
          end
        end
      end
    end

    context "remove monday and friday" do
      before do
        @route.update_attributes(monday: false, friday:false)
        @order.reload
        @order_times.map{|d, order| order.reload}
      end
      specify { @order.schedule.to_s.should match /Weekly on Sundays, Tuesdays, Wednesdays, Thursdays, and Saturdays/ }
      (Route::DAYS - [:monday, :friday]).each do |day|
        specify { @order_times[day].schedule.recurrence_times.should_not be_empty }
      end
      [:monday, :friday].each do |day|
        specify { @order_times[day].schedule.recurrence_times.should be_empty }
      end
    end
    context "remove most days" do
      before do
        @route.update_attributes(monday: false, tuesday: false, wednesday: false, thursday: false, friday: false, saturday: false)
        @order.reload
        @order_times.map{|d, order| order.reload}
      end

      specify { @order.schedule.to_s.should eq('Weekly on Sundays') }
      (Route::DAYS - [:sunday]).each do |day|
        specify { @order_times[day].schedule.recurrence_times.should be_empty }
      end
      [:sunday].each do |day|
        specify { @order_times[day].schedule.recurrence_times.should_not be_empty }
      end
    end
  end
end

