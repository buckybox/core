require 'spec_helper'

describe Bucky::Schedule do
  let(:time)        { Time.current }
  let(:next_sunday) { next_day(:sunday) }
  let(:work_week)   { [:monday, :tuesday, :wednesday, :thursday, :friday] }
  let(:single)      { new_single_schedule(next_sunday) }
  let(:weekly)      { new_recurring_schedule(next_sunday, work_week, 1) }
  let(:fortnightly) { new_recurring_schedule(next_sunday, work_week, 2) }
  let(:monthly)     { new_monthly_schedule(next_sunday, [2]) }

  describe '#initialize' do
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
    let(:time_offset)      { 1.week }
    let(:exception_offset) { 3.days }
    let(:single_time)      { time + time_offset }
    let(:weekly_rule)      { IceCube::Rule.weekly.day(0, 3, 6) }
    let(:monthly_rule)     { IceCube::Rule.monthly.day_of_week(0 => [1], 3 => [1], 6 => [1]) }
    let(:exception_time)   { (time + exception_offset).beginning_of_day }
    let(:full_schedule)    { new_full_schedule(time, single_time, weekly_rule, monthly_rule, exception_time) }

    context 'before utc' do
      before { Time.zone = 'Hong Kong' }

      describe '#to_hash' do
        before { @hash = full_schedule.to_hash }

        specify { @hash[:start_date].should == time.utc }
        specify { @hash[:rtimes][0].should == single_time.utc }
        specify { @hash[:extimes][0].should == exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [6, 2, 5] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 6 => [1], 2 => [1], 5 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(full_schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == full_schedule.start_time.to_s }
        specify { @new_schedule.start_time.zone.should == Time.current.zone }
        specify { @new_schedule.to_s.should == full_schedule.to_s }
      end
    end

    context 'at utc' do
      before { Time.zone = 'UTC' }

      describe '#to_hash' do
        before { @hash = full_schedule.to_hash }

        specify { @hash[:start_date].should == time.utc }
        specify { @hash[:rtimes][0].should == single_time.utc }
        specify { @hash[:extimes][0].should == exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [0, 3, 6] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 0 => [1], 3 => [1], 6 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(full_schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == full_schedule.start_time.to_s }
        specify { @new_schedule.start_time.zone.should == Time.current.zone }
        specify { @new_schedule.to_s.should == full_schedule.to_s }
      end
    end

    context 'after utc' do
      before { Time.zone = 'Mazatlan' }

      describe '#to_hash' do
        before { @hash = full_schedule.to_hash }

        specify { @hash[:start_date].should == time.utc }
        specify { @hash[:rtimes][0].should == single_time.utc }
        specify { @hash[:extimes][0].should == exception_time.utc }
        specify { @hash[:rrules][0][:validations][:day].should == [0, 3, 6] }
        specify { @hash[:rrules][1][:validations][:day_of_week].should == { 0 => [1], 3 => [1], 6 => [1] } }
      end

      describe '#from_hash' do
        before { @new_schedule = Bucky::Schedule.from_hash(full_schedule.to_hash) }

        specify { @new_schedule.class.should == Bucky::Schedule }
        specify { @new_schedule.start_time.to_s.should == full_schedule.start_time.to_s }
        specify { @new_schedule.start_time.zone.should == Time.current.zone }
        specify { @new_schedule.to_s.should == full_schedule.to_s }
      end
    end

    describe 'save as one timezone and recreate in another' do
      before do
        Time.zone      = 'Hong Kong'
        @schedule_hash = full_schedule.to_hash

        Time.zone     = 'Mazatlan'
        @new_schedule = Bucky::Schedule.from_hash(@schedule_hash)
      end

      specify { @new_schedule.class.should == Bucky::Schedule }
      specify { @new_schedule.start_time.to_s.should == (full_schedule.start_time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.recurrence_times[0].to_s.should == (single_time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.exception_times[0].to_s.should == (exception_time.in_time_zone('Mazatlan')).to_s }
      specify { @new_schedule.recurrence_rules[0].to_s.should == 'Weekly on Tuesdays, Fridays, and Saturdays' }
      specify { @new_schedule.recurrence_rules[1].to_s.should == 'Monthly on the 1st Saturday when it is the 1st Tuesday when it is the 1st Friday' }
    end
  end

  describe '#==' do
    let(:s1) { Bucky::Schedule.new(time) }
    let(:s2) { Bucky::Schedule.new(time) }
    let(:s3) { Bucky::Schedule.new(time + 1.hour) }

    specify { s1.should == s1 }
    specify { s1.should == s2 }
    specify { s1.should_not == s3 }
  end

  describe '#emtpy?' do
    let(:schedule) { Bucky::Schedule.new(time) }

    specify { schedule.empty?.should be_true }
    specify { single.empty?.should_not be_true }
    specify { weekly.empty?.should_not be_true }
    specify { monthly.empty?.should_not be_true }
  end

  describe "#include?" do
    context :identity do
      specify { single.should include_schedule(new_single_schedule(next_sunday)) }
      specify { weekly.should include_schedule(new_recurring_schedule(next_sunday, work_week, 1)) }
      specify { fortnightly.should include_schedule(new_recurring_schedule(next_sunday, work_week, 2)) }
      specify { monthly.should include_schedule(new_monthly_schedule(next_sunday)) }
    end

    context :start_times do
      # If the other schedule starts before this one, then it isn't going to match
      context "other schedule starts before this one" do
        specify { weekly.should_not include_schedule(new_recurring_schedule(next_sunday - 1.month, work_week, 1), true) }
        specify { fortnightly.should_not include_schedule(new_recurring_schedule(next_sunday - 1.month, work_week, 2), true) }
        specify { monthly.should_not include_schedule(new_monthly_schedule(next_sunday - 1.month), true) }
      end

      # If the other schedule starts after this one it should match
      context "other schedule starts after this one" do
        specify { weekly.should include_schedule(new_recurring_schedule(next_sunday + 1.month, work_week, 1)) }
        specify { fortnightly.should include_schedule(new_recurring_schedule(next_sunday + 1.month, work_week, 2)) }
        specify { monthly.should include_schedule(new_monthly_schedule(next_sunday + 1.month)) }
      end
    end

    context :single do
      specify { single.should_not include_schedule(weekly) }
      specify { single.should_not include_schedule(fortnightly) }
      specify { single.should_not include_schedule(monthly) }
    end

    context :weekly do
      specify { weekly.should_not include_schedule(single) }
      specify { weekly.should_not include_schedule(new_recurring_schedule(next_sunday, [:sunday], 2)) }
      specify { weekly.should include_schedule(fortnightly) }
      specify { weekly.should include_schedule(monthly) }

      it 'should include singles which fall on a reoccuring day' do
        next_tuesday = next_day(:tuesday, next_sunday)
        single_schedule = new_single_schedule(next_tuesday)
        weekly.should include_schedule(single_schedule)
      end
    end

    context :fortnightly do
      specify { fortnightly.should_not include_schedule(single) }
      specify { fortnightly.should_not include_schedule(weekly) }
      specify { fortnightly.should_not include_schedule(monthly) }

      it 'should include singles which fall on a reoccuring day' do
        next_tuesday = next_day(:tuesday, next_sunday)
        single_schedule = new_single_schedule(next_tuesday)
        fortnightly.should include_schedule(single_schedule)
      end
    end

    context :monthly do
      specify { monthly.should_not include_schedule(weekly) }
      specify { monthly.should_not include_schedule(fortnightly) }
      specify { monthly.should_not include_schedule(single) }

      shared_examples 'it matches single occurrences' do |day|
        it 'it matches single occurrences' do # Apparently need to nest this with an 'it' so that it can access let(:next_sunday) etc
          next_month = next_sunday + 1.month
          start_of_next_month = Time.zone.local(next_month.year, next_month.month, 1)
          next_monthly_day = next_day(day, start_of_next_month)
          monthly_schedule = new_monthly_schedule(next_sunday, [day])
          single_schedule = new_single_schedule(next_monthly_day)

          monthly_schedule.should include_schedule(single_schedule)
        end
      end
    end
  end

  describe "#recurrence_type" do
    specify { single.recurrence_type.should eq(:single) }
    specify { weekly.recurrence_type.should eq(:weekly) }
    specify { fortnightly.recurrence_type.should eq(:fortnightly) }
    specify { monthly.recurrence_type.should eq(:monthly) }
  end

  describe '#recurrence_days' do
    specify { single.recurrence_days.should == [] }
    specify { weekly.recurrence_days.should == [1, 2, 3, 4, 5] }
    specify { fortnightly.recurrence_days.should == [1, 2, 3, 4, 5] }
    specify { monthly.recurrence_days.should == [] }
  end

  describe '#month_days' do
    specify { single.month_days.should == [] }
    specify { weekly.month_days.should == [] }
    specify { fortnightly.month_days.should == [] }
    specify { monthly.month_days.should == [2] }
  end

  context 'when removing a recurrence days or times' do
    shared_examples 'it has removeable days' do
      before { schedule.remove_recurrence_rule_day(3) }
      specify { schedule.to_s.should_not match /Wednesday/i }
    end

    shared_examples 'it has removeable recurrance times' do
      before { schedule.add_recurrence_time(Time.zone.parse('next wednesday')) }

      context 'should remove a recurrance time on that day' do
        before { schedule.remove_recurrence_times_on_day(3) }
        specify { schedule.recurrence_times.size.should == 0 }
      end

      context 'should not remove a recurrance time on another day' do
        before { schedule.remove_recurrence_times_on_day(2) }
        specify { schedule.recurrence_times.size.should == 1 }
      end
    end

    context 'before UTC' do
      before { Time.zone = 'Hong Kong' }

      context 'for single schedule' do
        let(:schedule) { new_everyday_schedule(Time.current) }

        it_behaves_like 'it has removeable days'
        it_behaves_like 'it has removeable recurrance times'
      end

      context 'for recurring schedule' do
        let(:schedule) { new_monthly_schedule(Time.current, (0..6).to_a, ) }

        it_behaves_like 'it has removeable days'
        it_behaves_like 'it has removeable recurrance times'
      end
    end

    context 'after UTC' do
      before { Time.zone = 'Mazatlan' }

      context 'for single schedule' do
        let(:schedule) { new_everyday_schedule(Time.current) }

        it_behaves_like 'it has removeable days'
        it_behaves_like 'it has removeable recurrance times'
      end

      context 'for recurring schedule' do
        let(:schedule) { new_monthly_schedule(Time.current, (0..6).to_a, ) }

        it_behaves_like 'it has removeable days'
        it_behaves_like 'it has removeable recurrance times'
      end
    end
  end
end
