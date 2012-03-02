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

def new_everyday_schedule
  new_recurring_schedule(Time.now + 1.day, [:sunday, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday])
end
