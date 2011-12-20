class AddScheduleToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :schedule, :text
  end
end
