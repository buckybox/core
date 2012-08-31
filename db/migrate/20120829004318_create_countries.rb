class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name
      t.string :default_currency
      t.string :default_time_zone
      t.integer :default_consumer_fee_cents

      t.timestamps
    end

    add_column :distributors, :country_id, :integer
    add_column :distributors, :consumer_delivery_fee_cents, :integer
  end
end
