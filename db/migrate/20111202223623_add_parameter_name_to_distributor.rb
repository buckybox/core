class AddParameterNameToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :parameter_name, :string
  end
end
