include Bucky

#===== Custom matchers
RSpec::Matchers.define :include_schedule do |expected, strict_start_time|
  match do |actual|
    actual.include? expected, (strict_start_time || false)
  end
end

#===== Creation
def new_single_schedule(time = (Time.current + 1.day))
  schedule = Schedule.new(time)
  schedule.add_recurrence_time(time)

  return schedule
end

def new_recurring_schedule(time = (Time.current + 1.day), days = [:monday, :tuesday, :wednesday, :thursday, :friday], interval=1)
  schedule = Schedule.new(time)

  recurrence_rule = IceCube::Rule.weekly(interval).day(*days)
  schedule.add_recurrence_rule(recurrence_rule)

  return schedule
end

def new_everyday_schedule(time = (Time.current + 1.day))
  new_recurring_schedule(time , [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday])
end

def new_monthly_schedule(time = (Time.current + 1.day), days = [0], interval=1)
  schedule = Schedule.new(time)

  monthly_days_hash = days.to_a.inject({}) { |hash, day| hash[day] = [1]; hash }
  recurrence_rule = IceCube::Rule.monthly(interval).day_of_week(monthly_days_hash)
  schedule.add_recurrence_rule(recurrence_rule)

  return schedule
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
