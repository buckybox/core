require 'spec_helper'

describe ScheduleRule do
  context :one_off do
    let(:date){ Date.parse('2012-08-20') }
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
    end
  end
end
