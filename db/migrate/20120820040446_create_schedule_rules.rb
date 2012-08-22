class CreateScheduleRules < ActiveRecord::Migration
  def change
    create_table :schedule_rules do |t|
      t.string :recur
      t.date :start
      t.boolean :mon
      t.boolean :tue
      t.boolean :wed
      t.boolean :thu
      t.boolean :fri
      t.boolean :sat
      t.boolean :sun
      t.integer :order_id
      t.integer :schedule_pause_id

      t.timestamps
    end
  end
end
