require 'spec_helper'
include Bucky

describe Route do
  let (:route) { Fabricate.build(:route) }

  specify { route.should be_valid }

  context :route_days do
    specify { Fabricate.build(:route, monday: false).should_not be_valid }
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
    before do
      @distributor = Fabricate.build(:distributor)
      @distributor.routes.stub(:first).and_return(route)
    end

    it 'should just return the first one for now' do
      Route.default_route(@distributor).should == route
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

