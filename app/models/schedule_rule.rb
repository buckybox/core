class ScheduleRule < ActiveRecord::Base
  attr_accessible :finish, :fri, :mon, :month_day, :recur, :sat, :start_datetime, :sun, :thu, :tue, :wed, :order_id

  DAYS = [:mon, :tue, :wed, :thu, :fri, :sat, :sun]
  RECUR = [:one_off, :weekly, :fortnightly, :monthly]

  belongs_to :order
  
  def initalize(attrs)
    defaults = {time_zone: 'UTC'}
    super.new(defaults.merge(attrs))
  end

  def self.one_off(datetime)
    ScheduleRule.new(start_datetime: datetime)
  end

  def self.recur_on(start_datetime, days, recur)
    days &= DAYS #whitelist
    days = days.inject({}){|h, i| h.merge(i => true)} #Turn array into hash
    days = DAYS.inject({}){|h, i| h.merge(i => false)}.merge(days) # Fill out the rest with false

    throw "recur '#{recur}' is :weekly or :fortnightly" unless [:weekly, :fortnightly, :monthly].include?(recur)

    ScheduleRule.new(days.merge(recur: recur, start_datetime: start_datetime))
  end

  def self.weekly(start_datetime, days)
    recur_on(start_datetime, days, :weekly)
  end

  def self.fortnightly(start_datetime, days)
    recur_on(start_datetime, days, :fortnightly)
  end

  def self.monthly(start_datetime, days)
    recur_on(start_datetime, days, :monthly)
  end

  def recur
    r = read_attribute(:recur)
    if r.nil?
      :one_off
    else
      r.to_sym
    end
  end

  def occurs_on?(datetime)
    case recur
    when :one_off
      start_datetime == datetime
    when :weekly
      weekly_occurs_on?(datetime)
    when :fortnightly
      fortnightly_occurs_on?(datetime)
    when :monthly
      monthly_occurs_on?(datetime)
    end
  end

  def weekly_occurs_on?(datetime)
    day = datetime.strftime("%a").downcase.to_sym
    self.send("#{day}?") && start_datetime <= datetime
  end

  def fortnightly_occurs_on?(datetime)
    # So, theory is, the difference between the start_datetime and the date in question as days, devided by 7 should give the number of weeks since the start_datetime.  If the number is even, we are on a fortnightly.
    first_occurence = start_datetime + (datetime.wday - start_datetime.wday) + (start_datetime.wday >= datetime.wday ? 7 : 0)
    weekly_occurs_on?(datetime) && ((datetime - first_occurence) / 7).to_i.even? # 7 days in a week
  end

  def monthly_occurs_on?(datetime)
    weekly_occurs_on?(datetime) && datetime.day < 8
  end

  def self.generate_data(count)
    count.times do
      days = DAYS.shuffle[0..(rand(7))]
      start_datetime = Date.today - 700.days + (rand(1400).days)
      recur = [:one_off, :weekly, :fortnightly, :monthly].shuffle.first
      case recur
      when :one_off
        ScheduleRule.one_off(start_datetime)
      when :weekly
        ScheduleRule.weekly(start_datetime, days)
      when :fortnightly
        ScheduleRule.fortnightly(start_datetime, days)
      when :monthly
        ScheduleRule.monthly(start_datetime, days)
      end.save
    end
  end

  def self.ice_cube(schedule)
    start_datetime = schedule.start_time
    days = schedule.recurrence_days.map{|d| Date::DAYNAMES[d][0..2].downcase.to_sym}

    case schedule.frequency.to_s
    when 'single'
      ScheduleRule.one_off(start_datetime)
    when 'weekly'
      ScheduleRule.weekly(start_datetime, days)
    when 'fortnightly'
      ScheduleRule.fortnightly(start_datetime, days)
    when 'monthly'
      ScheduleRule.monthly(start_datetime, days)
    end
  end

  def self.copy_from_ice
    Distributor.all.each do |d|
      Time.zone = d.time_zone
      d.orders.all.each do |o|
        begin
          s = ice_cube(o.schedule)
          s.order = o
          s.save!
        rescue => e
          puts e
        end
      end
    end
  end
end
