class AddMonthlyBooleanToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :available_monthly, :boolean, default: false, null: false
  end
end
