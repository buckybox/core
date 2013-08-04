class AddUniquenessConstraintForNumberToCustomer < ActiveRecord::Migration
  def change
    add_index :customers, [:distributor_id, :number], :unique => true
  end
end
