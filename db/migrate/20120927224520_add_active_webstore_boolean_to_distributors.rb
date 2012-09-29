class AddActiveWebstoreBooleanToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :active_webstore, :boolean, default: false, null: false
  end
end
