class AddMorePhoneNumbersToAddress < ActiveRecord::Migration
  def up
    add_column :addresses, :phone_2, :string
    add_column :addresses, :phone_3, :string
  end

  def down
    remove_column :addresses, :phone_3
    remove_column :addresses, :phone_2
  end
end
