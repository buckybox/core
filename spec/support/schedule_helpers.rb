include Bucky

#===== Custom matchers
RSpec::Matchers.define :include_schedule do |expected, strict_start_time|
  match do |actual|
    actual.include? expected, (strict_start_time || false)
  end
end

#===== Creation
def new_single_schedule(date = (Date.current + 1.day))
  schedule_rule = ScheduleRule.one_off(date)
  return schedule_rule
end

def new_recurring_schedule(date = (Date.current + 1.day), days = [:mon, :tue, :wed, :thu, :fri], interval = 1)
  schedule_rule = interval == 1 ? ScheduleRule.weekly(date, days) : ScheduleRule.fortnightly(date, days)

  return schedule_rule
end

def new_everyday_schedule(date = (Date.current + 1.day))
  new_recurring_schedule(date, [:sun, :mon, :tue, :wed, :thu, :fri, :sat])
end

def new_monthly_schedule(date = (Date.current + 1.day), days = [:sun])
  schedule_rule = ScheduleRule.monthly(date, days)

  return schedule_rule
end

# Day needs to be an integer 0-6 representing the weekday
# return the next day that it is the required weekday
def next_day(day, time = Time.current)
  day = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].find_index(day) if day.is_a?(Symbol)
  nday = time + ((7 - (time.wday - day)) % 7).days

  return nday == 0 ? 7 : nday
end

# From
# http://www.jonathanspooner.com/web-development/ruby-time-nextfriday/
# Time.next(:friday)
class Time
  class << self
    def next(day, from = nil)
      day = [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday].find_index(day) if day.is_a?(Symbol)

      one_day = 60 * 60 * 24
      original_date = from || now
      result = original_date
      result += one_day until result > original_date && result.wday == day

      return result
    end
  end
end
