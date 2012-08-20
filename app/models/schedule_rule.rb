class ScheduleRule < ActiveRecord::Base
  attr_accessible :time_zone, :end_date, :fri, :mon, :month_day, :recur, :sat, :start_date, :sun, :thu, :tue, :wed

  DAYS = [:mon, :tue, :wed, :thu, :fri, :sat, :sun]
  RECUR = [:one_off, :weekly, :fortnightly, :monthly]
  
  def initalize(attrs)
    defaults = {time_zone: Time.zone}
    super.new(defaults.merge(attrs))
  end

  def self.one_off(date)
    ScheduleRule.new(start_date: date)
  end

  def self.weekly(start_date, days)
    days &= DAYS #whitelist
    days = days.inject({}){|h, i| h.merge(i => true)} #Turn array into hash
    days = DAYS.inject({}){|h, i| h.merge(i => false)}.merge(days) # Fill out the rest with false

    ScheduleRule.new(days.merge(recur: :weekly, start_date: start_date))
  end

  def recur
    r = read_attribute(:recur)
    if r.nil?
      :one_off
    else
      r.to_sym
    end
  end

  def occurs_on?(date)
    case recur
    when :one_off
      start_date == date
    when :weekly
      weekly_occurs_on?(date)
    when :fortnightly
      fortnightly_occurs_on?(date)
    when :monthly
      monthly_occurs_on?(date)
    end
  end

  def weekly_occurs_on?(date)
    day = date.strftime("%a").downcase.to_sym
    self.send("#{day}?") && start_date <= date
  end
end
