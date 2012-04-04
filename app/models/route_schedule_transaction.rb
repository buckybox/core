class RouteScheduleTransaction < ActiveRecord::Base
  include Bucky

  belongs_to :route

  has_one :distributor, through: :route

  schedule_for :schedule

  attr_accessible :route, :schedule

  validates_presence_of :route, :schedule

  default_scope order('created_at DESC')

  delegate :local_time_zone, to: :distributor, allow_nil: true
end
