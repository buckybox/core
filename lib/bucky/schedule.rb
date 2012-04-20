module Bucky
  class Schedule

    def self.build(start_time, frequency, days_by_number)
      schedule = Bucky::Schedule.new(start_time.utc)

      throw "days_by_number '#{days_by_number}' wasn't valid" if days_by_number.present? && (days_by_number & 0.upto(6).to_a).blank? # [nil, '', nil] & [0,1,2,3,4,5,6] = []

      days_by_number = adjust_days_for_time_zone(schedule, days_by_number)

      if frequency == 'single'
        schedule.add_recurrence_time(start_time.utc)
      elsif frequency == 'monthly'
        monthly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

        recurrence_rule = IceCube::Rule.monthly.day_of_week(monthly_days_hash)
        schedule.add_recurrence_rule(recurrence_rule)
      else
        if frequency == 'weekly'
          weeks_between_deliveries = 1
        elsif frequency == 'fortnightly'
          weeks_between_deliveries = 2
        else
          raise "#{frequency} does not match the expected single, monthly, weekly, fortnightly"
        end

        recurrence_rule = IceCube::Rule.weekly(weeks_between_deliveries).day(*days_by_number)
        schedule.add_recurrence_rule(recurrence_rule)
      end

      return schedule
    end

    def initialize(*args)
      if args.blank?
        @schedule = IceCube::Schedule.new(Time.current.utc)
      elsif args.first.is_a?(IceCube::Schedule)
        schedule = args.first

        # Convert to UTC
        schedule.start_time = schedule.start_time.utc unless schedule.start_time.blank?
        schedule.end_time = schedule.end_time.utc unless schedule.end_time.blank?

        @schedule = IceCube::Schedule.from_hash(schedule.to_hash)
      else
        start_time = args.first.utc
        options = args.second || {}

        options[:end_time] = options[:end_time].utc if options[:end_time].present?

        @schedule = IceCube::Schedule.new(start_time, options)
      end
    end

    def time_zone=(tz)
      tz = Time.zone if tz.nil?
      @time_zone = tz.clone
    end

    def time_zone
      @time_zone || Time.zone
    end

    def to_hash
      if @schedule.present?
        hash = @schedule.to_hash
        hash[:start_time] = hash.delete(:start_date)
        hash
      else
        {}
      end
    end

    def occurs_on?(date)
      # Not sure about converting to UTC here or not
      @schedule.occurs_on?(date)
    end

    def occurring_at?(time)
      @schedule.occurring_at?(time.utc)
    end

    def next_occurrence(from = Time.current)
      @schedule.next_occurrence(from.utc)
    end

    def next_occurrences(num, from = Time.current)
      @schedule.next_occurrences(num, from.utc)
    end

    def add_recurrence_time(time)
      @schedule.add_recurrence_time(time.utc)
    end

    def remove_recurrence_time(time)
      @schedule.remove_recurrence_time(time.utc)
    end

    def recurrence_times
      @schedule.recurrence_times.collect do |recurrence_time|
        if recurrence_time.respond_to?(:in_time_zone)
          recurrence_time.in_time_zone(time_zone)
        elsif recurrence_time.respond_to?(:to_time)
          recurrence_time.to_time.in_time_zone(time_zone)
        else
          recurrence_time
        end
      end
    end

    def add_recurrence_rule(rule)
      @schedule.add_recurrence_rule(rule)
    end

    def recurrence_rules
      @schedule.recurrence_rules
    end

    def occurrences_between(start_time, end_time)
      @schedule.occurrences_between(start_time.utc, end_time.utc)
    end

    def end_time
      @schedule.end_time.in_time_zone(time_zone) if @schedule.end_time
    end

    def end_time=(end_time)
      @schedule.end_time = end_time.utc
    end

    def start_time
      @schedule.start_time.in_time_zone(time_zone) if @schedule.start_time
    end

    def start_time=(time)
      @schedule.start_time = time.utc
    end

    def next_occurrence
      @schedule.next_occurrence.in_time_zone(time_zone) if @schedule.next_occurrence
    end

    def exception_times
      @schedule.exception_times
    end

    def remove_exception_time(time)
      @schedule.remove_exception_time(time.utc)
    end

    def add_exception_time(time)
      @schedule.add_exception_time(time.utc)
    end

    def exception_rules
      @schedule.exception_rules
    end

    def remove_recurrence_rule(rule)
      @schedule.remove_recurrence_rule(rule)
    end

    def remove_recurrence_rule_day(day)
      new_schedule = @schedule
      recurrence_rule = new_schedule.recurrence_rules.first

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
          @schedule = new_schedule
        else
          @schedule = nil
        end
      else
        nil
      end
    end

    def remove_recurrence_times_on_day(day)
      day = DAYS[day] if day.is_a?(Integer) && day.between?(0, 6)
      new_schedule = @schedule

      recurrence_times.each do |recurrence_time|
        if recurrence_time.send("#{day}?") # recurrence_time.monday? for example
          new_schedule.remove_recurrence_time(recurrence_time)
        end
      end

      @schedule = new_schedule
    end

    #Have copied the IceCube::Schedule.to_s method directly here to
    #convert back from utc.
    def to_s
      to_s_time_format = IceCube::TO_S_TIME_FORMAT
      pieces = []
      ed = @schedule.extimes; rd = @schedule.rtimes - ed
      pieces.concat rd.sort.map { |t| t.in_time_zone(time_zone).strftime(to_s_time_format) }
      pieces.concat @schedule.rrules.map { |t| t.to_s }
      pieces.concat @schedule.exrules.map { |t| "not #{t.in_time_zone(time_zone).to_s}" }
      pieces.concat ed.sort.map { |t| "not on #{t.in_time_zone(time_zone).strftime(to_s_time_format)}" }
      pieces << "until #{@schedule.end_time.in_time_zone(time_zone).strftime(to_s_time_format)}" if @schedule.end_time
      pieces.join(' / ')
    end

    def ==(schedule)
      return false unless schedule.is_a?(Bucky::Schedule)
      self.to_hash == schedule.to_hash
    end

    def self.from_hash(hash)
      hash[:start_date] = hash.delete(:start_time) if hash[:start_time].present? #IceCube is moving away from 'date' but this one is still there.
      Bucky::Schedule.new(IceCube::Schedule.from_hash(hash))
    end


    # Does the other_schedule fall on days in our schedule?
    # Check the spec to see how complex a match this accepts
    def include?(other_schedule, strict_start_time = false)
      raise "Given schedule is blank" if other_schedule.blank?

      expected = Bucky::Schedule
      raise "Given schedule isn't a #{expected}" unless other_schedule.is_a?(expected) 

      match = true
      if [:weekly, :fortnightly].include?(recurrence_type) && other_schedule.recurrence_type == :single
        match &= ([other_schedule.start_time.wday] - recurrence_days).empty?

      elsif recurrence_type == :weekly && other_schedule.recurrence_type == :monthly
        match &= (other_schedule.month_days - recurrence_days).empty? # The repeating days in the monthly schedule need to be a subset of this schedules weekly reoccuring days 

      elsif recurrence_type == :weekly && other_schedule.recurrence_type == :fortnightly
        match &= (other_schedule.recurrence_days - recurrence_days).empty?
        # is the other schedules recurrence_days a subset of mine?

        match &= (recurrence_times == other_schedule.recurrence_times)
      elsif [:monthly].include?(recurrence_type) && other_schedule.recurrence_type == :single
        match &= month_days.include?(other_schedule.start_time.wday)

      else
        match &= (recurrence_type == other_schedule.recurrence_type)
        match &= (other_schedule.recurrence_days - recurrence_days).empty?
        # is the other schedules recurrence_days a subset of mine?

        match &= (recurrence_times == other_schedule.recurrence_times)
      end

      match &= (start_time <= other_schedule.start_time) if strict_start_time # Optional

      match
    end

    # This is very much dependant on how BuckyBox is using IceCube and ignores the possibilites of
    # an interval higher than 2 and ignores intervals on MonthlyRules
    #
    # Doesn't support matching fortnights into weeks
    # E.g 'Weekdays Weekly' doesn't include 'Weekdays Fortnightly' dispite logically that being the case
    def recurrence_type
      if recurrence_rules.present?
        recurrence_rule = recurrence_rules.first
        interval = recurrence_rule.to_hash[:interval]
        type = case recurrence_rule
               when IceCube::WeeklyRule
                 interval==1 ? :weekly : :fortnightly
               when IceCube::MonthlyRule
                 :monthly
               end
      else
        :single
      end
    end

    def recurrence_days
      days = recurrence_rules.first.to_hash[:validations][:day] if recurrence_rules.first.present?
      days || []
    end

    def month_days
      days = recurrence_rules.first.to_hash[:validations][:day_of_week].keys if recurrence_type == :monthly && recurrence_rules.first.present?
      days || []
    end

    private

    def ice_cube_schedule
      @schedule
    end

    def self.adjust_days_for_time_zone(schedule, days_by_number)
      schedule.adjust_days_for_time_zone(days_by_number)
    end

    def adjust_days_for_time_zone(days_by_number)
      # Adjust to UTC based days
      days_by_number.map { |d| (d - 1) % 7 } if schedule.time_zone.utc_offset > 0

      return days_by_number.map { |d| d % 7 } # make sure days are 0 - 6
    end
  end
end
