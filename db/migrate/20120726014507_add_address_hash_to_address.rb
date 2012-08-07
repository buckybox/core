class AddAddressHashToAddress < ActiveRecord::Migration
  def up
    add_column :addresses, :address_hash, :string

    Address.transaction do
      Address.find_each do |address|
        address.update_address_hash
        address.save!
      end
    end

    add_index :addresses, :address_hash
  end

  def down
    remove_column :addresses, :address_hash
  end
end
