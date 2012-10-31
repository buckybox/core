class AddCityToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :city, :string
  end
end
