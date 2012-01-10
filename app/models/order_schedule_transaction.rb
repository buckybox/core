class OrderScheduleTransaction < ActiveRecord::Base
  include IceCube

  belongs_to :order

  serialize :schedule, Hash

  attr_accessible :order, :schedule

  validates_presence_of :order, :schedule

  default_scope order('created_at DESC')

  def schedule
    Schedule.from_hash(self[:schedule]) if self[:schedule]
  end

  def schedule=(schedule)
    self[:schedule] = schedule.to_hash
  end
end
