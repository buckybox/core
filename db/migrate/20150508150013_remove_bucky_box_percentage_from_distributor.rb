class RemoveBuckyBoxPercentageFromDistributor < ActiveRecord::Migration
  def change
    remove_column :distributors, :bucky_box_percentage
  end
end
