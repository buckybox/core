class CreateLocalisedAddresses < ActiveRecord::Migration
  def change
    create_table :localised_addresses do |t|
      t.references :addressable, polymorphic: true, null: false

      t.string :street
      t.string :city
      t.string :zip
      t.string :state

      t.timestamps
    end
  end
end
