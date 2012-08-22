class CreateSchedulePauses < ActiveRecord::Migration
  def change
    create_table :schedule_pauses do |t|
      t.date :start
      t.date :finish

      t.timestamps
    end
  end
end
