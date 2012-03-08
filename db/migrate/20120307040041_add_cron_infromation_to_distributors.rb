class AddCronInfromationToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :advance_hour, :integer
    add_column :distributors, :advance_days, :integer
    add_column :distributors, :automatic_delivery_hour, :integer

    remove_column :distributors, :daily_lists_schedule
    remove_column :distributors, :auto_delivery_schedule
  end
end
