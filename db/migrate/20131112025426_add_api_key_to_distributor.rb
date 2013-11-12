class AddApiKeyToDistributor < ActiveRecord::Migration
  def change
  	add_column :distributors, :api_key, :string
  	add_index :distributors, :api_key, unique: true
  end
end
