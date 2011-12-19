class AddScheduleToRoute < ActiveRecord::Migration
  def change
    add_column :routes, :schedule, :text
  end
end
