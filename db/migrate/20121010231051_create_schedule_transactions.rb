class CreateScheduleTransactions < ActiveRecord::Migration
  def change
    create_table :schedule_transactions do |t|
      t.text :schedule_rule
      t.integer :schedule_rule_id

      t.timestamps
    end
  end
end
