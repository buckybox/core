require 'spec_helper'
include Bucky

describe Schedule do
  context "#new" do
    context "with no args" do
      specify { lambda{ Schedule.new }.should_not raise_error }
      specify { Schedule.new.to_hash[:start_time].should be_utc }
    end

    context "with only start_time" do
      before do
        @time = Time.now
        @schedule = Schedule.new(@time)
      end
      specify { @schedule.to_hash[:start_time].should be_utc}
    end

    context "with start_time and end_time" do
      before do
        @time = Time.now
        @end_time = @time + 2.weeks
        @schedule = Schedule.new(@time, {end_time: @end_time})
      end
      specify { @schedule.to_hash[:start_time].should be_utc}
      specify { @schedule.to_hash[:end_time].should be_utc}
    end
  end

  context "#from_hash" do
    before do
      @schedule = Schedule.new
    end
    specify { Schedule.from_hash(@schedule.to_hash).should == @schedule }
  end

  context ".recurrence_times" do
    before do
      @schedule = Schedule.new
      @schedule.add_recurrence_time(1.week.from_now)
      @schedule.add_recurrence_time(Time.current)
    end
    specify { @schedule.send(:ice_cube_schedule).rtimes.each{|recurrence_time| recurrence_time.should be_utc } }
    specify { Time.use_zone("London") { @schedule.recurrence_times.each{|recurrence_time| recurrence_time.time_zone.to_s.should match(/London/)}} }
  end

  context :with_reoccuring_schedule do
    before do
      Time.zone = "Wellington"
      Delorean.time_travel_to(Time.parse("2012-03-15 15:47:08")) #It was failing at this point, and I am not sure if it was because London time 'GMT' goes to BST in 4 weeks-ish
      @schedule = Bucky::Schedule.from_hash({:start_date=>Time.parse("2012-02-14 00:00:00"), :rrules=>[{:validations=>{:day=>[0, 1, 2, 3, 4, 5, 6]}, :rule_type=>"IceCube::WeeklyRule", :interval=>1}], :exrules=>[], :rtimes=>[], :extimes=>[]})
      @thread = nil
    end

    after do
      @thread.kill if @thread.alive?
      Delorean.back_to_the_present
    end

    it 'should not loop forever' do
      @thread = Thread.new do
        Time.zone = "London"
        @schedule.occurrences_between(Time.current, 4.weeks.from_now)
      end
      count = 0
      while count < 10
        # Let it break early if we have fixed it
        break unless @thread.alive?
        count = count + 1
        # Sleep so that it has some time on the CPU
        sleep 0.01
      end
      # Should have finished by now, if not we can assume it will take forever
      @thread.should_not be_alive
    end
  end

  context "when removing a recurrence days or times" do
    shared_examples "it has removeable days" do
      it "should remove only the specified day" do
        schedule.to_s.should match /Wednesday/i
        schedule.remove_recurrence_rule_day(3)
        schedule.to_s.should_not match /Wednesday/i
      end
    end

    shared_examples "it has removeable recurrance times" do
      it "should remove a recurrance time on that day" do
        schedule.add_recurrence_time(Date.parse('next wednesday').to_time)
        schedule.remove_recurrence_times_on_day(3)
        schedule.recurrence_times.size.should == 0
      end

      it "should not remove a recurrance time on another day" do
        schedule.add_recurrence_time(Date.parse('next wednesday').to_time)
        schedule.remove_recurrence_times_on_day(2)
        schedule.recurrence_times.size.should == 1
      end
    end

    context "for single schedule" do
      let(:schedule) {
        Schedule.from_hash({
          :rrules => [
            {
              :validations => {:day => [0, 1, 3, 4, 5, 6]},
              :rule_type => "IceCube::WeeklyRule", :interval=>1
            }
          ]
        })
      }

      it_behaves_like "it has removeable days"
      it_behaves_like "it has removeable recurrance times"
    end

    context "for recurring schedule" do
      let(:schedule) {
        Schedule.from_hash({
          :rrules => [
            {
              :validations => { :day_of_week => {0=>[1], 1=>[1], 3=>[1], 4=>[1], 5=>[1], 6=>[1]}},
              :rule_type => "IceCube::MonthlyRule", :interval=>1
            }
          ]
        })
      }

      it_behaves_like "it has removeable days"
      it_behaves_like "it has removeable recurrance times"
    end
  end
end
