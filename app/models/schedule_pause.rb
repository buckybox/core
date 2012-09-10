class SchedulePause < ActiveRecord::Base
  attr_accessible :finish, :schedule_rule_id, :start

  def self.from_ice_cube(schedule)
    start = schedule.extimes.sort.first.to_date
    finish = schedule.extimes.sort.last.to_date

    SchedulePause.new(start: start, finish: finish) unless schedule.extimes.empty?
  end
end
