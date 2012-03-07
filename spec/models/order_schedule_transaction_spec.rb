require 'spec_helper'
include IceCube

describe OrderScheduleTransaction do
  before { @order_schedule_transaction = Fabricate(:order_schedule_transaction) }

  specify { @order_schedule_transaction.should be_valid }

  context :schedule do
    before do
      @time = Time.current
      @schedule = Schedule.new(@time)
      @order_schedule_transaction.schedule = @schedule
      @order_schedule_transaction.save
    end

    specify { @order_schedule_transaction.schedule.start_time.should == @schedule.start_time }
    specify { @order_schedule_transaction.schedule.to_hash.should == @schedule.to_hash }
  end
end
