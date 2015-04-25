require 'spec_helper'

describe ScheduleRule do
  let(:all_days){ScheduleRule::DAYS}
  context :one_off do
    let(:date){ Date.parse('2012-08-20') } # monday
    let(:schedule){ ScheduleRule.one_off(date) }

    specify { expect(schedule.occurs_on?(date)).to be true }
    specify { expect(schedule.occurs_on?(Date.parse('2012-08-21'))).to be false }
  end
  context :recur do
    let(:start_date){ Date.parse('2012-08-27') } # monday

    context :weekly do
      context :monday do
        let(:schedule){ ScheduleRule.weekly(start_date, [:mon])}

        it 'should repeat on mondays matching start date' do
          next_monday = Date.parse('2012-08-27')
          expect(schedule.occurs_on?(next_monday)).to be true
        end

        it 'should repeat on mondays matching start date' do
          next_monday = Date.parse('2012-09-03')
          expect(schedule.occurs_on?(next_monday)).to be true
        end

        it 'should not repeat on tuesday' do
          next_tuesday = Date.parse('2012-08-28')
          expect(schedule.occurs_on?(next_tuesday)).to be false
        end

        it 'should not occur on dates before start_date' do
          previous_monday = Date.parse('2012-08-20')
          expect(schedule.occurs_on?(previous_monday)).to be false
        end
      end
    end

    context :fortnightly do
      let(:schedule){ ScheduleRule.fortnightly(start_date, [:wed, :thu, :fri, :sun])}

      it 'should occur on first wednesday' do
        first_occurrence = Date.parse('2012-08-29')

        expect(schedule.occurs_on?(first_occurrence)).to be true
      end

      it 'should not occur on second wednesday' do
        first_occurrence = Date.parse('2012-08-29')
        expect(schedule.occurs_on?(first_occurrence+7.days)).to be false
      end

      it 'should not occur before start date' do
        first_occurrence = Date.parse('2012-08-29')
        expect(schedule.occurs_on?(first_occurrence-7.days)).to be false
      end

      it 'should occur on third wednesday' do
        first_occurrence = Date.parse('2012-08-29')
        expect(schedule.occurs_on?(first_occurrence+14.days)).to be true
      end

      it 'should occur on first thursday' do
        first_occurrence = Date.parse('2012-08-30')
        expect(schedule.occurs_on?(first_occurrence)).to be true
      end

      it 'should occur on first sunday' do
        first_occurrence = Date.parse('2012-09-09')
        expect(schedule.occurs_on?(first_occurrence)).to be true
      end

      it 'should occur on 10th sunday' do
        first_occurrence = Date.parse('2012-09-09')
        expect(schedule.occurs_on?(first_occurrence+10.weeks)).to be true
      end

      it 'should occur on 1000th sunday' do
        first_occurrence = Date.parse('2012-09-09')
        expect(schedule.occurs_on?(first_occurrence+1000.weeks)).to be true
      end
    end

    context :monthly do
      let(:schedule){ ScheduleRule.monthly(start_date, [:sun, :tue, :sat])}

      it 'should occur on the first week of the month after the start_date' do
        first_occurrence = Date.parse('2012-09-01') # Saturday

        expect(schedule.occurs_on?(first_occurrence)).to be true
      end

      it 'should not occur on the second week of the month after the start_date' do
        first_occurrence = Date.parse('2012-09-08') # Saturday

        expect(schedule.occurs_on?(first_occurrence)).to be false
      end

      it 'should correctly predict the next 20 occurrences' do
        sr = ScheduleRule.monthly(Date.current, [:thu])
        sr.save!
        sr.next_occurrences(20, Date.current).each do |d|
          expect(d.wday).to eq(4)
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
          expect(@sr.next_occurrence(@start_date - 1.day)).to eq(@start_date)
        end

        it 'should return null' do
          expect(@sr.next_occurrence(@start_date + 1.day)).to eq(nil)
        end

        it 'should return the start_date' do
          expect(@sr.next_occurrence(@start_date)).to eq(@start_date)
        end
      end

      context :weekly do
        before do
          @start_date = Date.parse('2012-09-20') # Thursday
          @sr = ScheduleRule.weekly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify{expect(@sr.next_occurrence(@start_date - 1.day)).to eq(@start_date)}
        specify{expect(@sr.next_occurrence(@start_date)).to eq(@start_date)}
        specify{expect(@sr.next_occurrence(@start_date + 1.day)).to eq(@start_date + 1.day)}

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-03')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end

          specify {expect(@sr.next_occurrence(@start_date)).to eq(@pause_end)}
          specify {expect(@sr.next_occurrence(@pause_end)).to eq(@pause_end)}

          it "should show the next occurrence, ignoring dates that are paused" do
            sr = ScheduleRule.weekly('2012-10-15', [:mon, :tue, :wed, :thu])
            sr.pause!('2012-10-15', '2012-10-16')
            expect(sr.next_occurrence(Date.parse('2012-10-14'))).to eq(Date.parse('2012-10-16'))
          end
        end
      end

      context :fortnightly do
        before do
          @start_date = Date.parse('2012-09-20') # Thursday
          @sr = ScheduleRule.fortnightly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify{expect(@sr.next_occurrence(@start_date - 1.day)).to eq(@start_date)}
        specify{expect(@sr.next_occurrence(@start_date)).to eq(@start_date)}
        specify{expect(@sr.next_occurrence(@start_date + 1.day)).to eq(@start_date + 1.day)}

        specify{expect(@sr.next_occurrence(Date.parse('2012-09-23'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-24'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-25'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-26'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-27'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-28'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-29'))).to eq(Date.parse('2012-09-30'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-09-30'))).to eq(Date.parse('2012-09-30'))}

        specify{expect(@sr.next_occurrence(Date.parse('2012-10-01'))).to eq(Date.parse('2012-10-03'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-02'))).to eq(Date.parse('2012-10-03'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-03'))).to eq(Date.parse('2012-10-03'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-04'))).to eq(Date.parse('2012-10-04'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-05'))).to eq(Date.parse('2012-10-05'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-06'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-07'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-08'))).to eq(Date.parse('2012-10-14'))}

        specify{expect(@sr.next_occurrence(Date.parse('2012-10-09'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-10'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-11'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-12'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-13'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-14'))).to eq(Date.parse('2012-10-14'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-15'))).to eq(Date.parse('2012-10-17'))}
        specify{expect(@sr.next_occurrence(Date.parse('2012-10-16'))).to eq(Date.parse('2012-10-17'))}

        specify{expect(@sr.next_occurrence(Date.parse('2022-04-17'))).to eq(Date.parse('2022-04-17'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-18'))).to eq(Date.parse('2022-04-20'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-19'))).to eq(Date.parse('2022-04-20'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-20'))).to eq(Date.parse('2022-04-20'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-21'))).to eq(Date.parse('2022-04-21'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-22'))).to eq(Date.parse('2022-04-22'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-23'))).to eq(Date.parse('2022-05-01'))}
        specify{expect(@sr.next_occurrence(Date.parse('2022-04-24'))).to eq(Date.parse('2022-05-01'))}

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-03')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end

          specify {expect(@sr.next_occurrence(@start_date)).to eq(@pause_end)}
          specify {expect(@sr.next_occurrence(@pause_end)).to eq(@pause_end)}
        end
      end

      context :monthly do
        before do
          @start_date = Date.parse('2012-09-20') # Thursday
          @sr = ScheduleRule.monthly(@start_date, [:sun, :wed, :thu, :fri])
          @sr.save!
        end

        specify {expect(@sr.next_occurrence(@start_date)).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-09-29'))).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-09-30'))).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-01'))).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-02'))).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-03'))).to eq(Date.parse('2012-10-03'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-04'))).to eq(Date.parse('2012-10-04'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-05'))).to eq(Date.parse('2012-10-05'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-06'))).to eq(Date.parse('2012-10-07'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-07'))).to eq(Date.parse('2012-10-07'))}
        specify {expect(@sr.next_occurrence(Date.parse('2012-10-08'))).to eq(Date.parse('2012-11-01'))}

        context 'with a specified week of the month' do
          before do
            @sr.week = 2
            @sr.save!
          end

          specify {expect(@sr.next_occurrence(Date.parse('2013-08-01'))).to eq Date.parse('2013-08-15')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-02'))).to eq Date.parse('2013-08-15')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-03'))).to eq Date.parse('2013-08-15')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-15'))).to eq Date.parse('2013-08-15')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-16'))).to eq Date.parse('2013-08-16')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-17'))).to eq Date.parse('2013-08-18')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-18'))).to eq Date.parse('2013-08-18')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-19'))).to eq Date.parse('2013-08-21')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-22'))).to eq Date.parse('2013-09-15')}
          specify {expect(@sr.next_occurrence(Date.parse('2013-08-31'))).to eq Date.parse('2013-09-15')}
        end

        context :with_pause do
          before do
            @pause_start = Date.parse('2012-09-20')
            @pause_end = Date.parse('2012-10-07')
            @sp = SchedulePause.new(start: @pause_start, finish: @pause_end)
            @sr.schedule_pause = @sp
            @sr.save!
          end

          specify {expect(@sr.next_occurrence(@start_date)).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-09-29'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-09-30'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-01'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-02'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-03'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-04'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-05'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-06'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-07'))).to eq(Date.parse('2012-10-07'))}
          specify {expect(@sr.next_occurrence(Date.parse('2012-10-08'))).to eq(Date.parse('2012-11-01'))}
        end
      end
    end
  end

  context :includes do
    let(:date){Date.parse('2012-10-03')} # wednesday

    specify{expect(Fabricate(:schedule_rule).includes?(Fabricate(:schedule_rule))).to be true}

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      expect(ScheduleRule.one_off(date).includes?(ScheduleRule.one_off(date))).to be true
    end

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      test_date = Date.parse('2012-10-05') # friday
      expect(ScheduleRule.weekly(date, ScheduleRule::DAYS).includes?(ScheduleRule.one_off(test_date))).to be true
    end

    it 'should return false for schedules which start too soon' do
      test_date = Date.parse('2012-10-01') # monday
      expect(ScheduleRule.weekly(date, ScheduleRule::DAYS).includes?(ScheduleRule.one_off(test_date))).to be false
    end

    it 'should return whether or not one schedule_rule occurs on the same days as another' do
      test_date = Date.parse('2012-10-05') # friday
      expect(ScheduleRule.weekly(date, ScheduleRule::DAYS - [:fri]).includes?(ScheduleRule.one_off(test_date))).to be false
    end

    it 'should return false if a pause makes it not occur on the required date of given schedule_rule' do
      test_date = Date.parse('2012-10-05') # friday
      sr = ScheduleRule.weekly(date, ScheduleRule::DAYS)
      sr.pause('2012-10-01', '2012-11-01')
      expect(sr.includes?(ScheduleRule.one_off(test_date))).to be false
    end

    it 'should return true if a pause doesnt occur within the given schedule_rule' do
      test_date = Date.parse('2012-10-05') # friday
      sr = ScheduleRule.weekly(date, ScheduleRule::DAYS)
      sr.pause('2012-11-01', '2012-12-01')
      expect(sr.includes?(ScheduleRule.one_off(test_date))).to be true
    end

    specify {expect(ScheduleRule.one_off(date).includes?(ScheduleRule.weekly(date, [:wed]))).to be false}
    specify {expect(ScheduleRule.one_off(date).includes?(ScheduleRule.fortnightly(date, all_days))).to be false}
    specify {expect(ScheduleRule.one_off(date).includes?(ScheduleRule.monthly(date, all_days))).to be false}

    specify {expect(ScheduleRule.weekly(date, all_days).includes?(ScheduleRule.fortnightly(date, all_days))).to be true}
    specify {expect(ScheduleRule.weekly(date, all_days).includes?(ScheduleRule.monthly(date, all_days))).to be true}

    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+3.days, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+4.days, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+7.days, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.weekly(date+11.days, all_days))).to be false}

    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date, all_days))).to be true}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+3.days, all_days))).to be true}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+4.days, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+7.days, all_days))).to be false}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date+11.days, all_days))).to be true}
    specify {expect(ScheduleRule.fortnightly(date, all_days).includes?(ScheduleRule.fortnightly(date + 14.days, all_days))).to be true}

    specify {expect(ScheduleRule.monthly(date, all_days).includes?(ScheduleRule.one_off(date))).to be true}
    specify {expect(ScheduleRule.monthly(date, all_days).includes?(ScheduleRule.one_off(Date.parse('2012-10-08')))).to be false}
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
    specify { expect(schedule_rule.deleted_days).to eq(ScheduleRule::DAYS) }
    specify do
      schedule_rule.attributes = {tue: true}
      expect(schedule_rule.deleted_days).to eq(ScheduleRule::DAYS - [:tue])
    end
  end

  describe '.deleted_day_numbers' do
    let(:schedule_rule){ScheduleRule.weekly}

    before do
      schedule_rule.update_attributes(mon: true, tue: true, wed: true, thu: true, fri: true, sat: true, sun: true)
      schedule_rule.attributes = {mon: false, tue: false, wed: false, thu: false, fri: false, sat: false, sun: false}
    end
    specify { expect(schedule_rule.deleted_day_numbers).to eq([0, 1, 2, 3, 4, 5, 6]) }
    specify do
      schedule_rule.attributes = {tue: true}
      expect(schedule_rule.deleted_day_numbers).to eq([0, 1, 3, 4, 5, 6])
    end
  end

  describe ".pause" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should create a matching schedule_pause" do
      schedule_rule.pause(Date.current, Date.current + 3.days)
      expect(schedule_rule.schedule_pause.start).to eq(Date.current)
      expect(schedule_rule.schedule_pause.finish).to eq(Date.current + 3.days)
    end
  end

  describe ".pause_date" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should return the start of the pause" do
      schedule_rule.pause(Date.current, Date.current + 4.days)
      expect(schedule_rule.pause_date).to eq(Date.current)
    end

    it "should be blank if pause has expired" do
      sr = ScheduleRule.weekly("2012-10-01", [:mon])
      sr.pause!("2012-09-01", "2012-09-29")
      expect(sr.pause_date).to be_blank
    end
  end

  describe ".resume_date" do
    let(:schedule_rule){ScheduleRule.weekly}

    it "should return the start of the pause" do
      schedule_rule.pause(Date.current, Date.current + 4.days)
      expect(schedule_rule.resume_date).to eq(Date.current + 4.days)
    end
  end

  describe ".occurrences" do
    let(:schedule_rule){Fabricate(:schedule_rule_weekly)}

    it "should return the next N occurrences" do
      today = Date.current
      schedule_rule.save!
      expect(schedule_rule.occurrences(14, today)).to eq(0.upto(13).collect{|i| today+i.days})
    end
  end

  describe ".occurrences_between" do
    let(:schedule_rule){Fabricate(:schedule_rule_weekly)}
    it "should return all occurrences between two given dates" do
      today = Date.current
      schedule_rule.save!
      expect(schedule_rule.occurrences_between(today, today+4.days)).to eq([today, today+1.day, today+2.days, today+3.days, today+4.days])
    end

    it "should skip pauses" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.pause!(today+2, today+3)
      expect(schedule_rule.occurrences_between(today, today+5.days)).to eq([today, today+1.day, today+3.days, today+4.days, today+5.days])
    end

    it "should allow pauses to be ignored" do
      today = Date.current
      schedule_rule.save!
      schedule_rule.pause!(today+2, today+4)
      expect(schedule_rule.occurrences_between(today, today+5.days, {ignore_pauses: true})).to eq([today, today+1.day, today+2.days, today+3.days, today+4.days, today+5.days])
    end
  end

  describe "#deliver_on" do
    it "should return a natural language string representing the schedule" do
      expect(ScheduleRule.one_off(Date.parse("2012-10-15")).deliver_on).to eq("Deliver on 15 Oct")
    end

    specify {expect(ScheduleRule.weekly(Date.parse("2012-10-16"), [:mon]).deliver_on).to eq("Deliver weekly on Monday")}
    specify {expect(ScheduleRule.fortnightly(Date.parse("2012-10-16"), [:mon]).deliver_on).to eq("Deliver fortnightly on Monday")}
    specify {expect(ScheduleRule.monthly(Date.parse("2012-10-16"), [:mon]).deliver_on).to eq("Deliver monthly on the first Monday")}

    specify {expect(ScheduleRule.weekly(Date.parse("2012-10-17"), ScheduleRule::DAYS).deliver_on).to eq("Deliver weekly on Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, and Saturday")}
  end

  describe ".pause_expired?" do
    it "should return true if a pause has expired" do
      sr = ScheduleRule.weekly("2012-10-01", [:mon])
      sr.pause!("2012-09-01", "2012-09-29")
      expect(sr.pause_expired?).to be true
    end
  end

  describe ".remove_day" do
    it "should remove that day from the schedule" do
      sr = ScheduleRule.weekly(Date.current, ScheduleRule::DAYS)
      expect(sr.mon).to be true
      sr.remove_day!(:monday)
      expect(sr.mon).to be false
    end
  end

  context :halted do
    it 'should not return any scheduled days when halted' do
      sr = ScheduleRule.weekly(Date.current, ScheduleRule::DAYS)
      sr.save!
      expect(sr.next_occurrence).not_to be_blank

      sr.halt!
      expect(sr.next_occurrence).to be_blank
    end

    it 'should notify associations when halted' do
      sr = ScheduleRule.weekly(Date.current, ScheduleRule::DAYS)
      expect(sr).to receive(:notify_associations)

      sr.halt!
    end

    it 'should notify associations when unhalted' do
      sr = ScheduleRule.weekly(Date.current, ScheduleRule::DAYS)
      expect(sr).to receive(:notify_associations)

      sr.unhalt!
    end
  end

  context :validations do
    it 'should not be valid without a day of the week' do
      sr = ScheduleRule.new({"recur" => "weekly", "start" => "2012-12-26"})
      expect(sr).not_to be_valid
    end
  end
end
