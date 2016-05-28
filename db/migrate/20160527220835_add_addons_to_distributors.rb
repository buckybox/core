class AddAddonsToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :addons, :string, null: false, default: ''
  end
end
