require 'spec_helper'
include IceCube

describe RouteScheduleTransaction do
  before { @route_schedule_transaction = Fabricate(:route_schedule_transaction) }

  specify { @route_schedule_transaction.should be_valid }

  context :schedule do
    before do
      @time = Time.now
      @schedule = Schedule.new(@time)
      @route_schedule_transaction.schedule = @schedule
      @route_schedule_transaction.save
    end

    specify { @route_schedule_transaction.schedule.start_time.should == @schedule.start_time }
    specify { @route_schedule_transaction.schedule.to_hash.should == @schedule.to_hash }
  end
end
