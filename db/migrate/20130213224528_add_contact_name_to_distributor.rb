class AddContactNameToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :contact_name, :string
  end
end
