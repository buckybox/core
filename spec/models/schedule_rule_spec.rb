require 'spec_helper'

describe ScheduleRule do
  let(:all_days){ScheduleRule::DAYS}
  context :one_off do
    let(:date){ Date.parse('2012-08-20') } #monday
    let(:schedule){ ScheduleRule.one_off(date) }

    specify { schedule.occurs_on?(date).should be_true }
    specify { schedule.occurs_on?(Date.parse('2012-08-21')).should be_false }
  end
  context :recur do
    let(:start_date){ Date.parse('2012-08-27') } #monday

    context :weekly do
      context :monday do
        let(:schedule){ ScheduleRule.weekly(start_date, [:mon])}

        it 'should repeat on mondays matching start date' do
          next_monday = Date.parse('2012-08-27')
          schedule.occurs_on?(next_monday).should be_true
        end

        it 'should repeat on mondays matching start date' do
          next_monday = Date.parse('2012-09-03')
          schedule.occurs_on?(next_monday).should be_true
        end

        it 'should not repeat on tuesday' do
          next_tuesday = Date.parse('2012-08-28')
          schedule.occurs_on?(next_tuesday).should be_false
        end

        it 'should not occur on dates before start_date' do
          previous_monday = Date.parse('2012-08-20')
          schedule.occurs_on?(previous_monday).should be_false
        end
      end
    end
    
    context :fortnightly do
      let(:schedule){ ScheduleRule.fortnightly(start_date, [:wed, :thu, :fri, :sun])}

      it 'should occur on first wednesday' do
        first_occurrence = Date.parse('2012-08-29')

        schedule.occurs_on?(first_occurrence).should be_true
      end
      
      it 'should not occur on second wednesday' do
        first_occurrence = Date.parse('2012-08-29')
        schedule.occurs_on?(first_occurrence+7.days).should be_false
      end

      it 'should not occur before start date' do
        first_occurrence = Date.parse('2012-08-29')
        schedule.occurs_on?(first_occurrence-7.days).should be_false
      end

      it 'should occur on third wednesday' do
        first_occurrence = Date.parse('2012-08-29')
        schedule.occurs_on?(first_occurrence+14.days).should be_true
      end

      it 'should occur on first thursday' do
        first_occurrence = Date.parse('2012-08-30')
        schedule.occurs_on?(first_occurrence).should be_true
      end

      it 'should occur on first sunday' do
        first_occurrence = Date.parse('2012-09-09')
        schedule.occurs_on?(first_occurrence).should be_true
      end
      
      it 'should occur on 10th sunday' do
        first_occurrence = Date.parse('2012-09-09')
        schedule.occurs_on?(first_occurrence+10.weeks).should be_true
      end

      it 'should occur on 1000th sunday' do
        first_occurrence = Date.parse('2012-09-09')
        schedule.occurs_on?(first_occurrence+1000.weeks).should be_true
      end
    end

    context :monthly do
      let(:schedule){ ScheduleRule.monthly(start_date, [:sun, :tue, :sat])}

      it 'should occur on the first week of the month after the start_date' do
        first_occurrence = Date.parse('2012-09-01') #Saturday
        
        schedule.occurs_on?(first_occurrence).should be_true
      end

      it 'should not occur on the second week of the month after the start_date' do
        first_occurrence = Date.parse('2012-09-08') #Saturday
        
        schedule.occurs_on?(first_occurrence).should be_false
      end

      it 'should correctly predict the next 20 occurrences' do
        sr = ScheduleRule.monthly(Date.current, [:thu])
        sr.save!
        sr.next_occurrences(20, Date.current).each do |d|
          d.wday.should eq(4)
        end
      end
    end
  end

  context :db_functions do
    context :next_occurrence do
      context :one_off do
        before do
          @start_date = Date.parse('2012-09-20')
          @sr = ScheduleRule.one_off(@start_date)
          @sr.save!
        end

        it 'should return the start_date' do
          @sr.next_occurrence(@start_date - 1.day).should eq(@start_date)
        end

        it 'should return null' do
          @sr.next_occurrence(@start_date + 1.day).should eq(nil)
        end

        it 'should return the start_date' do
          @sr.next_occurrence(@start_date).should eq(@start_date)
        end
      end

      context :weekly do
        before do
          @start_date = Date.parse('2012-09-20') #Thursday
          @sr = ScheduleRule.weekly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify{@sr.next_occurrence(@start_date - 1.day).should eq(@start_date)}
        specify{@sr.next_occurrence(@start_date).should eq(@start_date)}
        specify{@sr.next_occurrence(@start_date + 1.day).should eq(@start_date + 1.day)}

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-03')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end
          
          specify {@sr.next_occurrence(@start_date).should eq(@pause_end)}
          specify {@sr.next_occurrence(@pause_end).should eq(@pause_end)}

          it "should show the next occurrence, ignoring dates that are paused" do
            sr = ScheduleRule.weekly('2012-10-15', [:mon, :tue, :wed, :thu])
            sr.pause!('2012-10-15', '2012-10-16')
            sr.next_occurrence(Date.parse('2012-10-14')).should eq(Date.parse('2012-10-16'))
          end
        end
      end
      
      context :fortnightly do
        before do
          @start_date = Date.parse('2012-09-20') #Thursday
          @sr = ScheduleRule.fortnightly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify{@sr.next_occurrence(@start_date - 1.day).should eq(@start_date)}
        specify{@sr.next_occurrence(@start_date).should eq(@start_date)}
        specify{@sr.next_occurrence(@start_date + 1.day).should eq(@start_date + 1.day)}
        
        specify{@sr.next_occurrence(Date.parse('2012-09-23')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-24')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-25')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-26')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-27')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-28')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-29')).should eq(Date.parse('2012-09-30'))}
        specify{@sr.next_occurrence(Date.parse('2012-09-30')).should eq(Date.parse('2012-09-30'))}
        
        specify{@sr.next_occurrence(Date.parse('2012-10-01')).should eq(Date.parse('2012-10-03'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-02')).should eq(Date.parse('2012-10-03'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-03')).should eq(Date.parse('2012-10-03'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-04')).should eq(Date.parse('2012-10-04'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-05')).should eq(Date.parse('2012-10-05'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-06')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-07')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-08')).should eq(Date.parse('2012-10-14'))}
        
        specify{@sr.next_occurrence(Date.parse('2012-10-09')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-10')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-11')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-12')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-13')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-14')).should eq(Date.parse('2012-10-14'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-15')).should eq(Date.parse('2012-10-17'))}
        specify{@sr.next_occurrence(Date.parse('2012-10-16')).should eq(Date.parse('2012-10-17'))}
        
        specify{@sr.next_occurrence(Date.parse('2022-04-17')).should eq(Date.parse('2022-04-17'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-18')).should eq(Date.parse('2022-04-20'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-19')).should eq(Date.parse('2022-04-20'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-20')).should eq(Date.parse('2022-04-20'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-21')).should eq(Date.parse('2022-04-21'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-22')).should eq(Date.parse('2022-04-22'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-23')).should eq(Date.parse('2022-05-01'))}
        specify{@sr.next_occurrence(Date.parse('2022-04-24')).should eq(Date.parse('2022-05-01'))}

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-03')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end
          
          specify {@sr.next_occurrence(@start_date).should eq(@pause_end)}
          specify {@sr.next_occurrence(@pause_end).should eq(@pause_end)}
        end
      end

      context :monthly do
        before do
          @start_date = Date.parse('2012-09-20') #Thursday
          @sr = ScheduleRule.monthly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify {@sr.next_occurrence(@start_date).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-09-29')).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-09-30')).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-01')).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-02')).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-03')).should eq(Date.parse('2012-10-03'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-04')).should eq(Date.parse('2012-10-04'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-05')).should eq(Date.parse('2012-10-05'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-06')).should eq(Date.parse('2012-10-07'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-07')).should eq(Date.parse('2012-10-07'))}
        specify {@sr.next_occurrence(Date.parse('2012-10-08')).should eq(Date.parse('2012-11-01'))}

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-07')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end

          specify {@sr.next_occurrence(@start_date).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-09-29')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-09-30')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-01')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-02')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-03')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-04')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-05')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-06')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-07')).should eq(Date.parse('2012-10-07'))}
          specify {@sr.next_occurrence(Date.parse('2012-10-08')).should eq(Date.parse('2012-11-01'))}
        end
      end

    end
  end

  context :includes do
    let(:date){Date.parse('2012-10-03')} #wednesday

    specify{Fabricate(:schedule_rule).includes?(Fabricate(:schedule_rule)).should be_true}

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      ScheduleRule.one_off(date).includes?(ScheduleRule.one_off(date)).should be_true
    end

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      test_date = Date.parse('2012-10-05') #friday
      ScheduleRule.weekly(date, ScheduleRule::DAYS).includes?(ScheduleRule.one_off(test_date)).should be_true
    end
    
    it 'should return false for schedules which start too soon' do
      test_date = Date.parse('2012-10-01') #monday
      ScheduleRule.weekly(date, ScheduleRule::DAYS).includes?(ScheduleRule.one_off(test_date)).should be_false
    end

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      test_date = Date.parse('2012-10-05') #friday
      ScheduleRule.weekly(date, ScheduleRule::DAYS - [:fri]).includes?(ScheduleRule.one_off(test_date)).should be_false
    end

    it 'should return false if a pause makes it not occur on the required date of given schedule_rule' do
      test_date = Date.parse('2012-10-05') #friday
      sr = ScheduleRule.weekly(date, ScheduleRule::DAYS)
      sr.pause('2012-10-01', '2012-11-01')
      sr.includes?(ScheduleRule.one_off(test_date)).should be_false
    end
    
    it 'should return true if a pause doesnt occur within the given schedule_rule' do
      test_date = Date.parse('2012-10-05') #friday
      sr = ScheduleRule.weekly(date, ScheduleRule::DAYS)
      sr.pause('2012-11-01', '2012-12-01')
      sr.includes?(ScheduleRule.one_off(test_date)).should be_true
    end

    specify {ScheduleRule.one_off(date).includes?(ScheduleRule.weekly(date, [:wed])).should be_false}
    specify {ScheduleRule.one_off(date).includes?(ScheduleRule.fortnightly(date, all_days)).should be_false}
    specify {ScheduleRule.one_off(date).includes?(ScheduleRule.monthly(date, all_days)).should be_false}
    
    specify {ScheduleRule.weekly(date, all_days).includes?(ScheduleRule.fortnightly(date, all_days)).should be_true}
    specify {ScheduleRule.weekly(date, all_days).includes?(ScheduleRule.monthly(date, all_days)).should be_true}

    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+3.days, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+4.days, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+7.days, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+11.days, all_days)).should be_false}

    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date, all_days)).should be_true}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+3.days, all_days)).should be_true}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+4.days, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+7.days, all_days)).should be_false}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+11.days, all_days)).should be_true}
    specify {ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date + 14.days, all_days)).should be_true}

    specify {ScheduleRule.monthly(date, all_days).includes?(ScheduleRule.one_off(date)).should be_true}
    specify {ScheduleRule.monthly(date, all_days).includes?(ScheduleRule.one_off(Date.parse('2012-10-08'))).should be_false}
  end

  context :schedule_transaction do
    it "should create a schedule_transaction when saved if changed" do
      schedule_rule = ScheduleRule.weekly
      schedule_rule.sun = !schedule_rule.sun
      expect{schedule_rule.save!}.to change{ScheduleTransaction.count}.by(1)
    end
  end
  
  describe '.deleted_days' do
    let(:schedule_rule){ScheduleRule.weekly}

    before do
      schedule_rule.update_attributes(mon: true, tue: true, wed: true, thu: true, fri: true, sat: true, sun: true)
      schedule_rule.attributes = {mon: false, tue: false, wed: false, thu: false, fri: false, sat: false, sun: false}
    end
    specify { schedule_rule.deleted_days.should eq(ScheduleRule::DAYS) }
    specify { 
      schedule_rule.attributes = {tue: true}
      schedule_rule.deleted_days.should eq(ScheduleRule::DAYS - [:tue])
    }
  end

  describe '.deleted_day_numbers' do
    let(:schedule_rule){ScheduleRule.weekly}

    before do
      schedule_rule.update_attributes(mon: true, tue: true, wed: true, thu: true, fri: true, sat: true, sun: true)
      schedule_rule.attributes = {mon: false, tue: false, wed: false, thu: false, fri: false, sat: false, sun: false}
    end
    specify { schedule_rule.deleted_day_numbers.should eq([0, 1, 2, 3, 4, 5, 6]) }
    specify { 
      schedule_rule.attributes = {tue: true}
      schedule_rule.deleted_day_numbers.should eq([0, 1, 3, 4, 5, 6])
    }
  end

  describe ".pause" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should create a matching schedule_pause" do
      schedule_rule.pause(Date.current, Date.current + 3.days)
      schedule_rule.schedule_pause.start.should eq(Date.current)
      schedule_rule.schedule_pause.finish.should eq(Date.current + 3.days)
    end
  end

  describe ".pause_date" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should return the start of the pause" do
      schedule_rule.pause(Date.current, Date.current + 4.days)
      schedule_rule.pause_date.should eq(Date.current)
    end

    it "should be blank if pause has expired" do
      sr = ScheduleRule.weekly("2012-10-01")
      sr.pause!("2012-09-01", "2012-09-29")
      sr.pause_date.should be_blank
    end
  end

  describe ".resume_date" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should return the start of the pause" do
      schedule_rule.pause(Date.current, Date.current + 4.days)
      schedule_rule.resume_date.should eq(Date.current + 4.days)
    end
  end

  describe ".occurrences" do
    let(:schedule_rule){Fabricate(:schedule_rule_weekly)}

    it "should return the next N occurrences" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.occurrences(14, today).should eq(0.upto(13).collect{|i| today+i.days})
    end
  end

  describe ".occurrences_between" do
    let(:schedule_rule){Fabricate(:schedule_rule_weekly)}
    it "should return all occurrences between two given dates" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.occurrences_between(today, today+4.days).should eq([today, today+1.day, today+2.days, today+3.days, today+4.days])
    end

    it "should skip pauses" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.pause!(today+2, today+3)
      schedule_rule.occurrences_between(today, today+5.days).should eq([today, today+1.day, today+3.days, today+4.days, today+5.days])
    end

    it "should allow pauses to be ignored" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.pause!(today+2, today+4)
      schedule_rule.occurrences_between(today, today+5.days, {ignore_pauses: true}).should eq([today, today+1.day, today+2.days, today+3.days, today+4.days, today+5.days])
    end
  end

  describe ".to_s" do
    it "should return a natural language string representing the schedule" do
      ScheduleRule.one_off(Date.parse("2012-10-15")).to_s.should eq("15 Oct")
    end

    specify {ScheduleRule.weekly(Date.parse("2012-10-16"), [:mon]).to_s.should eq("Weekly on Mon")}
    specify {ScheduleRule.fortnightly(Date.parse("2012-10-16"), [:mon]).to_s.should eq("Fortnightly on Mon")}
    specify {ScheduleRule.monthly(Date.parse("2012-10-16"), [:mon]).to_s.should eq("Monthly on the 1st Mon")}

    specify {ScheduleRule.weekly(Date.parse("2012-10-17"), ScheduleRule::DAYS).to_s.should eq("Weekly on Sun, Mon, Tue, Wed, Thu, Fri, Sat")}
  end

  describe ".pause_expired?" do
    it "should return true if a pause has expired" do
      sr = ScheduleRule.weekly("2012-10-01")
      sr.pause!("2012-09-01", "2012-09-29")
      sr.pause_expired?.should be_true
    end
  end
  
  describe ".remove_day" do
    it "should remove that day from the schedule" do
      sr = ScheduleRule.weekly(Date.current, ScheduleRule::DAYS)
      sr.mon.should be_true
      sr.remove_day!(:monday)
      sr.mon.should be_false
    end
  end
end
