class AddWeekToScheduleRule < ActiveRecord::Migration
  def change
    add_column :schedule_rules, :week, :integer, default: 0
  end
end
