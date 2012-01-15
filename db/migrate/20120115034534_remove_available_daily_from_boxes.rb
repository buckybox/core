class RemoveAvailableDailyFromBoxes < ActiveRecord::Migration
  def up
    remove_column :boxes, :available_daily
  end

  def down
    add_column :boxes, :available_daily, :boolean
  end
end
