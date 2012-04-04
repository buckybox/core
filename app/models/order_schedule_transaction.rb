class OrderScheduleTransaction < ActiveRecord::Base
  include Bucky

  belongs_to :order

  has_one :distributor, through: :order

  schedule_for :schedule

  attr_accessible :order, :schedule

  validates_presence_of :order, :schedule

  default_scope order('created_at DESC')

  delegate :local_time_zone, to: :distributor, allow_nil: true
end
