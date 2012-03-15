class AddCronInfromationToDistributors < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end

  def up
    add_column :distributors, :advance_hour, :integer
    add_column :distributors, :advance_days, :integer
    add_column :distributors, :automatic_delivery_hour, :integer

    remove_column :distributors, :daily_lists_schedule
    remove_column :distributors, :auto_delivery_schedule

    Distributor.reset_column_information

    Distributor.all.each do |distributor|
      distributor.update_attributes(advance_hour: 18, advance_days: 3, automatic_delivery_hour: 18)
    end
  end

  def down
    add_column :distributors, :auto_delivery_schedule, :text
    add_column :distributors, :daily_lists_schedule, :text

    remove_column :distributors, :automatic_delivery_hour
    remove_column :distributors, :advance_days
    remove_column :distributors, :advance_hour
  end
end
