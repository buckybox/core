class RemoveBuckyBoxPercentageDefault < ActiveRecord::Migration
  def up
    change_column_default :distributors, :bucky_box_percentage, nil
  end

  def down
    change_column_default :distributors, :bucky_box_percentage, 0.0175
  end
end

