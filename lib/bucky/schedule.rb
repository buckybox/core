################################################################################################
#                                                                                              #
#  General idea is as such. Schedules that the app deals with are set to the app's time zone.  #
#  Before they are saved as a hash to the DB everything is changed to UTC, both single times   #
#  and rules. Same goes when pulling out a hash from the DB and creating a schedule object.    #
#                                                                                              #
################################################################################################

class Bucky::Schedule < IceCube::Schedule

  ################################################################################################
  #                                                                                              #
  #  Pretty specific to BuckyBox. The common way we create schedules.                            #
  #                                                                                              #
  ################################################################################################

  def self.build(start_time, frequency, days_by_number)
    schedule = Bucky::Schedule.new(start_time.utc)

    throw "days_by_number '#{days_by_number}' wasn't valid" if days_by_number.present? && (days_by_number & 0.upto(6).to_a).blank? # [nil, '', nil] & [0,1,2,3,4,5,6] = []

    days_by_number = adjust_days_for_time_zone(schedule, days_by_number)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time.utc)
    elsif frequency == 'monthly'
      monthly_days_hash = days_by_number.inject({}) { |hash, day| hash[day] = [1]; hash }

      recurrence_rule = IceCube::Rule.monthly.day_of_week(monthly_days_hash)
      schedule.add_recurrence_rule(recurrence_rulegst)
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

  ################################################################################################
  #                                                                                              #
  #  Methods to help deal with mass changes to schedules.                                        #
  #                                                                                              #
  ################################################################################################

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

  def ==(schedule)
    return false unless schedule.is_a?(Bucky::Schedule)
    self.to_hash == schedule.to_hash
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
end
