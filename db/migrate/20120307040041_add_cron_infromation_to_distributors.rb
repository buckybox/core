class AddCronInfromationToDistributors < ActiveRecord::Migration
  def up
    add_column :distributors, :advance_hour, :integer
    add_column :distributors, :advance_days, :integer
    add_column :distributors, :automatic_delivery_hour, :integer

    remove_column :distributors, :daily_lists_schedule
    remove_column :distributors, :auto_delivery_schedule
  end

  def down
    add_column :distributors, :auto_delivery_schedule, :text
    add_column :distributors, :daily_lists_schedule, :text

    remove_column :distributors, :automatic_delivery_hour
    remove_column :distributors, :advance_days
    remove_column :distributors, :advance_hour
  end
end
