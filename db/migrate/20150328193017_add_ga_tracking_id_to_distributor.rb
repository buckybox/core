class AddGaTrackingIdToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :ga_tracking_id, :string, null: true
  end
end
