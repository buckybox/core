class AddStatusToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :status, :string, default: "trial", null: false
  end
end
