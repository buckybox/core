class Route < ActiveRecord::Base
  include IceCube

  belongs_to :distributor

  has_many :deliveries

  serialize :schedule, Hash

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday

  validates_presence_of :distributor, :name
  validate :at_least_one_day_is_selected

  before_save :create_schedule

  def self.best_route(distributor)
    distributor.routes.first # For now the first one is the default
  end

  def schedule
    Schedule.from_hash(self[:schedule])
  end

  def next_run
    schedule.next_occurrence
  end

  def delivery_days
    [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday].select { |day| self[day] }
  end

  protected

  def at_least_one_day_is_selected
    unless [monday, tuesday, wednesday, thursday, friday, saturday, sunday].any?
      errors[:base] << "You must select at least one day for the route."
    end
  end

  def create_schedule
    recurrence_rule = Rule.weekly.day(*delivery_days)
    new_schedule = Schedule.new(Date.today.to_time)
    new_schedule.add_recurrence_rule(recurrence_rule)
    self.schedule = new_schedule.to_hash
  end
end
