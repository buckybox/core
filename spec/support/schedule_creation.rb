include IceCube

def new_single_schedule(time = (Time.now + 1.day))
  schedule = Schedule.new(time)
  schedule.add_recurrence_time(time)

  return schedule
end

def new_recurring_schedule(time = (Time.now + 1.day))
  schedule = Schedule.new(time)

  recurrence_rule = Rule.weekly(1).day(:monday, :tuesday, :wednesday, :thursday, :friday)
  schedule.add_recurrence_rule(recurrence_rule)

  return schedule
end
