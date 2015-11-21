class RemoveDistributorMetric < ActiveRecord::Migration
  def change
    drop_table :distributor_metrics
  end
end
