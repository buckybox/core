class ScheduleRule < ActiveRecord::Base
  attr_accessible :time_zone, :end_date, :fri, :mon, :month_day, :recur, :sat, :start_date, :sun, :thu, :tue, :wed

  DAYS = [:mon, :tue, :wed, :thu, :fri, :sat, :sun]
  RECUR = [:one_off, :weekly, :fortnightly, :monthly]
  
  def initalize(attrs)
    defaults = {time_zone: 'UTC'}
    super.new(defaults.merge(attrs))
  end

  def self.one_off(date)
    ScheduleRule.new(start_date: date)
  end

  def self.recur_on(start_date, days, recur)
    days &= DAYS #whitelist
    days = days.inject({}){|h, i| h.merge(i => true)} #Turn array into hash
    days = DAYS.inject({}){|h, i| h.merge(i => false)}.merge(days) # Fill out the rest with false

    throw "recur '#{recur}' is :weekly or :fortnightly" unless [:weekly, :fortnightly, :monthly].include?(recur)

    ScheduleRule.new(days.merge(recur: recur, start_date: start_date))
  end

  def self.weekly(start_date, days)
    recur_on(start_date, days, :weekly)
  end

  def self.fortnightly(start_date, days)
    recur_on(start_date, days, :fortnightly)
  end

  def self.monthly(start_date, days)
    recur_on(start_date, days, :monthly)
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

  def fortnightly_occurs_on?(date)
    # So, theory is, the difference between the start date and the date in question as days, devided by 7 should give the number of weeks since the start date.  If the number is even, we are on a fortnightly.
    first_occurence = start_date + (date.wday - start_date.wday) + (start_date.wday >= date.wday ? 7 : 0)
    weekly_occurs_on?(date) && ((date - first_occurence) / 7).to_i.even? # 7 days in a week
  end

  def monthly_occurs_on?(date)
    weekly_occurs_on?(date) && date.day < 8
  end
end
