class MobilePhoneNumberToAddress < ActiveRecord::Migration
  def up
    add_column :addresses, :mobile, :string
  end

  def down
    remove_column :addresses, :mobile
  end
end
