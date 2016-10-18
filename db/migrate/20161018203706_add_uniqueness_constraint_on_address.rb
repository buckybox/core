class AddUniquenessConstraintOnAddress < ActiveRecord::Migration
  def change
    remove_index :addresses, :customer_id

    add_index :addresses, :customer_id, unique: true
  end
end
