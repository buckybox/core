module Bucky
  class Schedule

    def initialize(*args)
      if args.first.is_a?(IceCube::Schedule)
        @schedule = IceCube::Schedule.from_hash(args.first.to_hash)
      else
        @schedule = IceCube::Schedule.new(*args)
      end
    end

    def time_zone=(tz)
      @time_zone = tz.clone
    end

    def time_zone
      @time_zone.clone
    end

    def to_hash
      @schedule.to_hash
    end

    def frequency
      @schedule.frequency
    end

    def frequency=(frequency)
      @schedule.frequency = frequency
    end

    def end_time
      @schedule.end_time
    end

    def end_time=(end_time)
      @schedule.end_time = end_time
    end

    def occurs_on?(time)
      @schedule.occurs_on?(time)
    end

    def occurring_at?(time)
      @schedule.occurring_at?(time)
    end

    def next_occurrence(*args)
      @schedule.next_occurrence(args)
    end

    def next_occurrences(*args)
      @schedule.next_occurrences(*args)
    end

    def add_recurrence_time(time)
      @schedule.add_recurrence_time(time)
    end

    def remove_recurrence_time(time)
      @schedule.remove_recurrence_time(time)
    end

    def recurrence_times
      @schedule.recurrence_times
    end

    def add_recurrence_rule(rule)
      @schedule.add_recurrence_rule(rule)
    end

    def recurrence_rules
      @schedule.recurrence_rules
    end

    def occurrences_between(start_time, end_time)
      @schedule.occurrences_between(start_time, end_time)
    end

    def start_time
      @schedule.start_time
    end

    def start_time=(time)
      @schedule.start_time = time
    end

    def start_date
      @schedule.start_date
    end

    def next_occurrence
      @schedule.next_occurrence
    end

    def exception_times
      @schedule.exception_times
    end

    def remove_exception_time(time)
      @schedule.remove_exception_time(time)
    end

    def add_exception_time(time)
      @schedule.add_exception_time(time)
    end

    def exception_rules
      @schedule.exception_rules
    end

    def remove_recurrence_rule(rule)
      @schedule.remove_recurrence_rule(rule)
    end

    def remove_recurrence_day(day)
      recurrence_rule = @schedule.recurrence_rules.first
      new_schedule = @schedule

      if recurrence_rule.present?
        new_schedule.remove_recurrence_rule(recurrence_rule)
        interval = recurrence_rule.to_hash[:interval]
        days = nil

        rule = case recurrence_rule
               when IceCube::WeeklyRule
                 days = recurrence_rule.to_hash[:validations][:day] || []

                 IceCube::Rule.weekly(interval).day(*(days - [day]))
               when IceCube::MonthlyRule
                 days = recurrence_rule.to_hash[:validations][:day_of_week].keys || []

                 monthly_days_hash = (days - [day]).inject({}) { |hash, day| hash[day] = [1]; hash }
                 IceCube::Rule.monthly(interval).day_of_week(monthly_days_hash)
               end

        if rule.present? && (days - [day]).present?
          new_schedule.add_recurrence_rule(rule)
          self.schedule = new_schedule
        else
          self.schedule = nil
        end
      else
        nil
      end
    end

    def use_local_time_zone
      Time.use_zone(@time_zone) do
        yield
      end
    end

    def to_s
      @schedule.to_s
    end

    def self.from_hash(hash)
      Bucky::Schedule.new(IceCube::Schedule.from_hash(hash))
    end
  end
end
