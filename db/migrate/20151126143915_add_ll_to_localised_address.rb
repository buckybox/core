class AddLlToLocalisedAddress < ActiveRecord::Migration
  def change
    add_column :localised_addresses, :lat, :decimal, precision: 15, scale: 10
    add_column :localised_addresses, :lng, :decimal, precision: 15, scale: 10
  end
end
