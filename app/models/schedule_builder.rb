class ScheduleBuilder
  def initialize(args)
    @start_date = Date.parse(args[:start_date].to_s)
    @frequency  = args[:frequency].to_s.to_sym
    @days       = args[:days]
  end

  def self.build(args)
    schedule_builder = new(args)
    schedule_builder.build
  end

  def build
    single? ? one_off : recurring
  end

  def single?
    frequency == :single
  end

private

  attr_reader :start_date
  attr_reader :frequency
  attr_reader :days

  def one_off
    ScheduleRule.one_off(start_date)
  end

  def recurring
    ScheduleRule.recur_on(start_date, days_of_the_week, frequency, week)
  end

  def days_of_the_week
    @days_of_the_week ||= days_of_the_month.map { |number| ScheduleRule.day(number) }
  end

  def days_of_the_month
    @days_of_the_month ||= days.keys
  end

  def week
    @week ||= days_of_the_month.first / ScheduleRule.number_of_days
  end
end
