class AddHaltedToScheduleRule < ActiveRecord::Migration
  def change
    add_column :schedule_rules, :halted, :boolean, default: false
  end
end
