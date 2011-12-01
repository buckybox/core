class AddNameAndUrlToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :name, :string
    add_column :distributors, :url, :string
  end
end
