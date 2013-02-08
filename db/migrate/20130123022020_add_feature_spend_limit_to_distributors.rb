class AddFeatureSpendLimitToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :feature_spend_limit, :boolean
  end
end
