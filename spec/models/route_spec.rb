require 'spec_helper'

describe Route do
  before { @route = Fabricate(:route) }

  specify { @route.should be_valid }

  context :route_days do
    specify { Fabricate.build(:route, :monday => false).should_not be_valid }
  end

  context :schedule do
    before do
      @route.monday    = true
      @route.tuesday   = false
      @route.wednesday = true
      @route.thursday  = false
      @route.friday    = true
      @route.saturday  = false
      @route.sunday    = false
      @route.save
    end
    specify { @route.schedule.should_not be_nil }
    specify { @route.schedule.to_s.should == "Weekly on Mondays, Wednesdays, and Fridays" }
  end

  describe '#best_route' do
    it 'should just return the first one for now' do
      Route.best_route(@route.distributor).should == @route
    end
  end

  describe '#delivery_days' do
    before { @route.friday = true }
    it 'should return any array of all the selected days' do
      @route.delivery_days.should == [:monday, :friday]
    end
  end
end

