require 'spec_helper'

describe ScheduleRule, :focus do
  context :one_off do
    let(:date){ Date.parse('2012-08-20') }
    let(:schedule){ ScheduleRule.one_off(date) }

    specify { schedule.occurs_on?(date).should be_true }
    specify { schedule.occurs_on?(Date.parse('2012-08-21')).should be_false }
  end

  context :weekly do
    let(:start_date){ Date.parse('2012-08-27') } #monday

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
end
