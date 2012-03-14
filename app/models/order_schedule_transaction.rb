class OrderScheduleTransaction < ActiveRecord::Base
  include Bucky

  belongs_to :order

  schedule_for :schedule

  attr_accessible :order, :schedule

  validates_presence_of :order, :schedule

  default_scope order('created_at DESC')

  def local_time_zone
    order.local_time_zone
  end
end
