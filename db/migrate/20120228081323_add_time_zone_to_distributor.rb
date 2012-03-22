class AddTimeZoneToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :time_zone, :string

  end
end
