class CreateScheduleRules < ActiveRecord::Migration
  def change
    create_table :schedule_rules do |t|
      t.string :time_zone
      t.string :recur
      t.date :start_date
      t.date :end_date
      t.integer :month_day
      t.boolean :mon
      t.boolean :tue
      t.boolean :wed
      t.boolean :thu
      t.boolean :fri
      t.boolean :sat
      t.boolean :sun

      t.timestamps
    end
  end
end
