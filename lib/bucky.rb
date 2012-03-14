module Bucky
  autoload :Schedule, 'bucky/schedule'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def schedule_for(name)
      self.serialize name, Hash

      define_method name do
        bs = nil
        if self[name]
          bs = Bucky::Schedule.from_hash(self[name])
          bs.time_zone = local_time_zone
        end
        bs
      end

      define_method "#{name}=" do |s|
        if s.is_a?(Hash)
          throw("Please don't pass in a Hash")
        elsif s.nil?
          self[name] = {}
        elsif s.is_a?(Bucky::Schedule)
          self[name] = s.to_hash
        else
          throw("Expecting a Bucky::Schedule but got a #{s.class}")
        end
      end
    end
  end

  def self.create_schedule(start_time, frequency, days_by_number = nil)
    schedule = Bucky::Schedule.new(start_time)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time)
    elsif frequency == 'monthly'
      monthly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

      recurrence_rule = Rule.monthly.day_of_week(monthly_days_hash)
      schedule.add_recurrence_rule(recurrence_rule)
    else
      if frequency == 'weekly'
        weeks_between_deliveries = 1
      elsif frequency == 'fortnightly'
        weeks_between_deliveries = 2
      end

      recurrence_rule = Rule.weekly(weeks_between_deliveries).day(*days_by_number)
      schedule.add_recurrence_rule(recurrence_rule)
    end

    schedule
  end

  def remove_recurrence_times_on_day(day)
    day = Route::DAYS[day] if day.is_a?(Integer) && day.between?(0, 6)
    new_schedule = schedule
    schedule.recurrence_times.each do |recurrence_time|
      if recurrence_time.send("#{day}?") # recurrence_time.monday? for example
        new_schedule.remove_recurrence_time(recurrence_time)
      end
    end
    self.schedule = new_schedule
  end

end

