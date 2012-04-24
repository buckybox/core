require 'spec_helper'

describe Bucky::Schedule do
  describe '#initialize' do
    let(:time)     { Time.current }
    let(:end_time) { time + 1.week }
    let(:duration) { 1.hour }

    specify { Bucky::Schedule.new.class.should == Bucky::Schedule }

    context 'with options' do
      before do
        @time = time
        @options = { end_time: end_time, duration: duration }
      end

      specify { Bucky::Schedule.new(time, @options).class.should == Bucky::Schedule }
      specify { Bucky::Schedule.new(time, @options).start_time.should == time }
      specify { Bucky::Schedule.new(time, @options).end_time.should == end_time }
    end
  end

  describe '#build' do
    let(:start_time) { Time.current + 3.days }

    context 'single' do
      before { @schedule = Bucky::Schedule.build(start_time, 'single') }

      specify { @schedule.class.should == Bucky::Schedule }
      specify { @schedule.start_time.should == start_time }
      specify { @schedule.recurrence_times[0].should == start_time }
    end

    context 'weekly' do
      before { @schedule = Bucky::Schedule.build(start_time, 'weekly', [0, 3, 6]) }

      specify { @schedule.class.should == Bucky::Schedule }
      specify { @schedule.start_time.should == start_time }
      specify { @schedule.recurrence_rules[0].to_s.should == 'Weekly on Sundays, Wednesdays, and Saturdays' }
    end

    context 'fortnightly' do
      before { @schedule = Bucky::Schedule.build(start_time, 'fortnightly', [0, 3, 6]) }

      specify { @schedule.class.should == Bucky::Schedule }
      specify { @schedule.start_time.should == start_time }
      specify { @schedule.recurrence_rules[0].to_s.should == 'Every 2 weeks on Sundays, Wednesdays, and Saturdays' }
    end

    context 'monthly' do
      before { @schedule = Bucky::Schedule.build(start_time, 'monthly', [0, 3, 6]) }

      specify { @schedule.class.should == Bucky::Schedule }
      specify { @schedule.start_time.should == start_time }
      specify { @schedule.recurrence_rules[0].to_s.should == 'Monthly on the 1st Sunday when it is the 1st Wednesday when it is the 1st Saturday' }
    end

    context 'bad parameters' do
      specify { expect { Bucky::Schedule.build(start_time, 'all_the_days', [0, 3, 7]) }.should raise_error  }
      specify { expect { Bucky::Schedule.build(start_time, 'monthly') }.should raise_error  }
      specify { expect { Bucky::Schedule.build(start_time, 'monthly', [0, 3, 7]) }.should raise_error  }
      specify { expect { Bucky::Schedule.build(start_time, 'monthly', [-1, 3, 6]) }.should raise_error }
    end
  end

  # This if very much only testing how we use IceCube (and how we have modified it)
  # Recurrence Times
  # Recurrence Rules (Weekly day, Montly days_of_week)
  # Exception Times
  # NOT Exception Rules
  context 'persistance' do
    let(:weekly_rule)      { IceCube::Rule.weekly.day(0, 3, 6) }
    let(:monthly_rule)     { IceCube::Rule.monthly.day_of_week(0 => [1], 3 => [1], 6 => [1]) }
    let(:time_offset)      { 1.week }
    let(:exception_offset) { 3.days }

    context 'before utc' do
      before do
        Time.zone       = 'Hong Kong'
        @current_time   = Time.current
        @time           = @current_time + time_offset
        @exception_time = (@current_time + exception_offset).beginning_of_day

        @schedule = Bucky::Schedule.new(@current_time)
        @schedule.add_recurrence_time(@time)
        @schedule.add_exception_time(@exception_time)
        @schedule.add_recurrence_rule(weekly_rule)
        @schedule.add_recurrence_rule(monthly_rule)
      end

      describe '#to_hash' do
        before { @hash = @schedule.to_hash }

        specify { @hash[:start_date].should == @current_time.utc }
        specify { @hash[:rtimes][0].should == @time.utc }
        specify { @hash[:extimes][0].should == @exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [6, 2, 5] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 6 => [1], 2 => [1], 5 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(@schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == @schedule.start_time.to_s }
        specify { @new_schedule.to_s.should == @schedule.to_s }
      end
    end

    context 'at utc' do
      before do
        Time.zone       = 'UTC'
        @current_time   = Time.current
        @time           = @current_time + time_offset
        @exception_time = (@current_time + exception_offset).beginning_of_day

        @schedule = Bucky::Schedule.new(@current_time)
        @schedule.add_recurrence_time(@time)
        @schedule.add_exception_time(@exception_time)
        @schedule.add_recurrence_rule(weekly_rule)
        @schedule.add_recurrence_rule(monthly_rule)
      end

      describe '#to_hash' do
        before { @hash = @schedule.to_hash }

        specify { @hash[:start_date].should == @current_time.utc }
        specify { @hash[:rtimes][0].should == @time.utc }
        specify { @hash[:extimes][0].should == @exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [0, 3, 6] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 0 => [1], 3 => [1], 6 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(@schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == @schedule.start_time.to_s }
        specify { @new_schedule.to_s.should == @schedule.to_s }
      end
    end

    context 'after utc' do
      before do
        Time.zone       = 'Mazatlan'
        @current_time   = Time.current
        @time           = @current_time + time_offset
        @exception_time = (@current_time + exception_offset).beginning_of_day

        @schedule = Bucky::Schedule.new(@current_time)
        @schedule.add_recurrence_time(@time)
        @schedule.add_exception_time(@exception_time)
        @schedule.add_recurrence_rule(weekly_rule)
        @schedule.add_recurrence_rule(monthly_rule)
      end

      describe '#to_hash' do
        before { @hash = @schedule.to_hash }

        specify { @hash[:start_date].should == @current_time.utc }
        specify { @hash[:rtimes][0].should == @time.utc }
        specify { @hash[:extimes][0].should == @exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [0, 3, 6] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 0 => [1], 3 => [1], 6 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(@schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == @schedule.start_time.to_s }
        specify { @new_schedule.to_s.should == @schedule.to_s }
      end
    end

    describe 'save as one timezone and recreate in another' do
      before do
        Time.zone       = 'Hong Kong'
        @current_time   = Time.current
        @time           = @current_time + time_offset
        @exception_time = (@current_time + exception_offset).beginning_of_day

        @schedule = Bucky::Schedule.new(@current_time)
        @schedule.add_recurrence_time(@time)
        @schedule.add_exception_time(@exception_time)
        @schedule.add_recurrence_rule(weekly_rule)
        @schedule.add_recurrence_rule(monthly_rule)
        @schedule_hash = @schedule.to_hash

        Time.zone = 'Mazatlan'
        @new_schedule = Bucky::Schedule.from_hash(@schedule_hash)
      end

      specify { @new_schedule.class.should == Bucky::Schedule }
      specify { @new_schedule.start_time.to_s.should == (@schedule.start_time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.recurrence_times[0].to_s.should == (@time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.exception_times[0].to_s.should == (@exception_time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.recurrence_rules[0].to_s.should == 'Weekly on Tuesdays, Fridays, and Saturdays' }
      specify { @new_schedule.recurrence_rules[1].to_s.should == 'Monthly on the 1st Saturday when it is the 1st Tuesday when it is the 1st Friday' }
    end
  end
end
