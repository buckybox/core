class CreateCronLogs < ActiveRecord::Migration
  def change
    create_table :cron_logs do |t|
      t.text :log

      t.timestamps
    end
  end
end
