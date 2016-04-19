class AddIntercomIdToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :intercom_id, :string
  end
end
