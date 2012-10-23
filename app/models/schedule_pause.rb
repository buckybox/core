class SchedulePause < ActiveRecord::Base
  attr_accessible :finish, :schedule_rule_id, :start

  has_one :schedule_rule, dependent: :destroy

  def self.from_ice_cube(schedule)
    start = schedule.extimes.sort.first.to_date
    finish = schedule.extimes.sort.last.to_date
    

    finish = nil if (finish - start).days == Bucky::Schedule::PAUSE_UFN
    SchedulePause.new(start: start, finish: finish) unless schedule.extimes.empty?
  end
end
