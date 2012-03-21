class AddDetailsToCronLog < ActiveRecord::Migration
  def change
    add_column :cron_logs, :details, :text
  end
end
