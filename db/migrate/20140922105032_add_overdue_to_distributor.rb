class AddOverdueToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :overdue, :string, null: false, default: ""
  end
end
