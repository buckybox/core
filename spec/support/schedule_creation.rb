include IceCube

def new_single_schedule(time = (Time.now + 1.day))
  schedule = Schedule.new(time)
  schedule.add_recurrence_time(time)

  return schedule
end

def new_recurring_schedule(time = (Time.now + 1.day), days = [:monday, :tuesday, :wednesday, :thursday, :friday])
  schedule = Schedule.new(time)

  recurrence_rule = Rule.weekly(1).day(*days)
  schedule.add_recurrence_rule(recurrence_rule)

  return schedule
end

def new_everyday_schedule(time = (Time.now + 1.day))
  new_recurring_schedule(time , [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday])
end

# From
# http://www.jonathanspooner.com/web-development/ruby-time-nextfriday/
# Time.next(:friday)
class Time
  class << self
    def next(day, from = nil)
      day = [:sunday,:monday,:tuesday,:wednesday,:thursday,:friday,:saturday].find_index(day) if day.class == Symbol
      one_day = 60 * 60 * 24
      original_date = from || now
      result = original_date
      result += one_day until result > original_date && result.wday == day 
      result
    end
  end
end
