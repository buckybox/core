class RouteScheduleTransaction < ActiveRecord::Base
  include IceCube

  belongs_to :route

  serialize :schedule, Hash

  attr_accessible :route, :schedule

  validates_presence_of :route, :schedule

  default_scope order('created_at DESC')

  def schedule
    Schedule.from_hash(self[:schedule]) if self[:schedule]
  end

  def schedule=(schedule)
    self[:schedule] = schedule.to_hash
  end
end
