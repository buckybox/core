require 'spec_helper'

describe Distributor do
  context :initialize do
    before { @distributor = Fabricate(:distributor, :email => ' BuckyBox@example.com ') }

    specify { @distributor.should be_valid }
    specify { @distributor.parameter_name.should == @distributor.name.parameterize }
    specify { @distributor.email.should == 'buckybox@example.com' }
  end

  context 'daily automation' do
    context 'default times' do
      before do
        time_now = Time.new
        Time.stub(:new).and_return(time_now)

        @build_lists_time = Time.new.beginning_of_day
        @delivery_time    = Time.new.end_of_day

        @distributor = Fabricate.build(:distributor)
        @distributor.generate_daily_lists_schedule
        @distributor.generate_auto_delivery_schedule
        @distributor.save
      end

      specify { @distributor.daily_lists_schedule.start_time == @build_lists_time }
      specify { @distributor.daily_lists_schedule.to_s == 'Daily' }
      specify { @distributor.daily_lists_schedule.next_occurrence == (@build_lists_time + 1.day) }
      specify { @distributor.auto_delivery_schedule.start_time == @delivery_time }
      specify { @distributor.auto_delivery_schedule.to_s == 'Daily' }
      specify { @distributor.auto_delivery_schedule.next_occurrence == (@delivery_time + 1.day) }
    end

    context 'custom times' do
      before do
        time_now = Time.new
        Time.stub(:new).and_return(time_now)

        @build_lists_time = Time.new.beginning_of_day + 6.hours + 32.minutes
        @delivery_time    = Time.new.beginning_of_day + 18.hours + 49.minutes

        @distributor = Fabricate.build(:distributor)
        @distributor.generate_daily_lists_schedule(@build_lists_time)
        @distributor.generate_auto_delivery_schedule(@delivery_time)
        @distributor.save

        @build_lists_time = Time.new.beginning_of_day + 6.hours
        @delivery_time    = Time.new.beginning_of_day + 18.hours
      end

      specify { @distributor.daily_lists_schedule.start_time == @build_lists_time }
      specify { @distributor.daily_lists_schedule.to_s == 'Daily' }
      specify { @distributor.daily_lists_schedule.next_occurrence == (@build_lists_time + 1.day) }
      specify { @distributor.auto_delivery_schedule.start_time == @delivery_time }
      specify { @distributor.auto_delivery_schedule.to_s == 'Daily' }
      specify { @distributor.auto_delivery_schedule.next_occurrence == (@delivery_time + 1.day) }
    end
  end
end
