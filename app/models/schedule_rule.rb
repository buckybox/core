class ScheduleRule < ActiveRecord::Base
  attr_accessible :fri, :mon, :month_day, :recur, :sat, :start, :sun, :thu, :tue, :wed, :order_id
  attr_accessor :next_occurrence

  DAYS = [:mon, :tue, :wed, :thu, :fri, :sat, :sun]
  RECUR = [:one_off, :weekly, :fortnightly, :monthly]

  belongs_to :order
  belongs_to :schedule_pause, dependent: :destroy

  scope :with_next_occurrence, (lambda do |date|
    select("schedule_rules.*, next_occurrence('#{date.to_s(:db)}', schedule_rules.*) as next_occurrence")
  end)

  def self.one_off(datetime)
    ScheduleRule.new(start: datetime)
  end

  def self.recur_on(start, days, recur)
    days &= DAYS #whitelist
    days = days.inject({}){|h, i| h.merge(i => true)} #Turn array into hash
    days = DAYS.inject({}){|h, i| h.merge(i => false)}.merge(days) # Fill out the rest with false

    throw "recur '#{recur}' is :weekly or :fortnightly" unless [:weekly, :fortnightly, :monthly].include?(recur)

    ScheduleRule.new(days.merge(recur: recur, start: start))
  end

  def self.weekly(start, days)
    recur_on(start, days, :weekly)
  end

  def self.fortnightly(start, days)
    recur_on(start, days, :fortnightly)
  end

  def self.monthly(start, days)
    recur_on(start, days, :monthly)
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
      start == datetime
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
    self.send("#{day}?") && start<= datetime
  end

  def fortnightly_occurs_on?(datetime)
    # So, theory is, the difference between the start and the date in question as days, devided by 7 should give the number of weeks since the start.  If the number is even, we are on a fortnightly.
    first_occurence = start - start.wday
    weekly_occurs_on?(datetime) && ((datetime - first_occurence) / 7).to_i.even? # 7 days in a week
  end

  def monthly_occurs_on?(datetime)
    weekly_occurs_on?(datetime) && datetime.day < 8
  end

  def next_occurrence(date=nil)
    date ||= Date.current
    write_attribute("next_occurrence", ScheduleRule.where(id:self.id).with_next_occurrence(date).first.attributes["next_occurrence"]) unless attributes["next_occurrence"] || new_record?
    
    if attributes["next_occurrence"].nil?
      nil
    else
      Date.parse attributes["next_occurrence"]
    end
  end

  def self.generate_data(count)
    count.times do
      days = DAYS.shuffle[0..(rand(7))]
      start= Date.today - 700.days + (rand(1400).days)
      recur = [:one_off, :weekly, :fortnightly, :monthly].shuffle.first
      case recur
      when :one_off
        ScheduleRule.one_off(start)
      when :weekly
        ScheduleRule.weekly(start, days)
      when :fortnightly
        ScheduleRule.fortnightly(start, days)
      when :monthly
        ScheduleRule.monthly(start, days)
      end.save
    end
  end

  def self.copy_orders_schedule(o)
    s = ice_cube(o.schedule)
    s.order = o

    unless o.schedule.extimes.empty?
      sp = SchedulePause.from_ice_cube(o.schedule) 
      sp.save!
      s.schedule_pause = sp
    end
    s
  end

  def self.ice_cube(schedule)
    start = schedule.start_time.to_date
    days = schedule.recurrence_days.map{|d| Date::DAYNAMES[d][0..2].downcase.to_sym}

    case schedule.frequency.to_s
    when 'single'
      ScheduleRule.one_off(start)
    when 'weekly'
      ScheduleRule.weekly(start, days)
    when 'fortnightly'
      ScheduleRule.fortnightly(start, days)
    when 'monthly'
      days = schedule.rrules.first.to_hash[:validations][:day_of_week].collect(&:first).map{|d| Date::DAYNAMES[d][0..2].downcase.to_sym}
      ScheduleRule.monthly(start, days)
    end
  end

  def self.copy_from_ice
    Distributor.all.each do |d|
      Time.zone = d.time_zone
      d.orders.all.each do |o|
        begin
          s = copy_orders_schedule(o)
          s.save!
        rescue => e
          puts e
        end
      end
    end
  end

  def self.test(d_id=nil, days=100)
    Distributor.all.each do |d|
      next if d_id && d_id != d.id
      d.use_local_time_zone do
        ((Date.tomorrow)..(Date.tomorrow+days.days)).each do |date|
          throw "FUCK #{d.id} - #{date.to_s}" unless collect_list(d, date).deliveries.collect(&:id).sort == Bucky::Sql.order_ids(d, date).sort
        end
      end
    end
  end

  def self.test_next
     ScheduleRule.select("id, next_occurrence('#{Date.today.to_s(:db)}', schedule_rules.*)").all.collect{|q|
      [q.id, q.next_occurrence]
    }.collect{|q|
      sr = ScheduleRule.find(q.first)
      if sr.order && sr.order.distributor
        sr.order.distributor.use_local_time_zone do
          q + [sr.order.try(:schedule).try(:next_occurrence).try(:to_date).try(:to_s,:db)]
        end
      end
    }.compact.select{|q| q[1] != q[2] }
  end

  FutureDeliveryList = Struct.new(:date, :deliveries)

  # For testing accuracy
  def self.collect_list(distributor, date, orders=nil)
    date_orders = []
    wday = date.wday
    
    orders ||= distributor.orders.active.includes({ account: {customer: {address:{}, deliveries: {delivery_list: {}}}}, order_extras: {}, box: {}})

    orders.each { |order| date_orders << order if order.schedule.occurs_on?(date) }

    # This emulates the ordering when lists are actually created
    FutureDeliveryList.new(date, date_orders.sort { |a,b|
      comp = a.dso(wday) <=> b.dso(wday)
      comp.zero? ? (b.created_at <=> a.created_at) : comp
    })
  end  
  
end
