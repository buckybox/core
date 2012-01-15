class AddAvailableDailyToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :available_daily, :boolean, :default => false, :null => false
  end
end
