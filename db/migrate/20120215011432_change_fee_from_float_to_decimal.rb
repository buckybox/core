class ChangeFeeFromFloatToDecimal < ActiveRecord::Migration
  def up
    change_column :distributors, :fee, :decimal, default: 0.0175, null: false
    rename_column :distributors, :fee, :bucky_box_percentage
  end

  def down
    rename_column :distributors, :bucky_box_percentage, :fee
    change_column :distributors, :fee, :float, default: 0.0175
  end
end
