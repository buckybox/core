class RouteScheduleTransaction < ActiveRecord::Base
  include Bucky

  belongs_to :route

  schedule_for :schedule

  attr_accessible :route, :schedule

  validates_presence_of :route, :schedule

  default_scope order('created_at DESC')

  def local_time_zone
    route.local_time_zone
  end
end
