class CreateScheduleRules < ActiveRecord::Migration
  def change
    create_table :schedule_rules do |t|
      t.string :recur
      t.timestamp :start_datetime
      t.date :end_datetime
      t.integer :month_day
      t.boolean :mon
      t.boolean :tue
      t.boolean :wed
      t.boolean :thu
      t.boolean :fri
      t.boolean :sat
      t.boolean :sun
      t.integer :order_id

      t.timestamps
    end
  end
end
