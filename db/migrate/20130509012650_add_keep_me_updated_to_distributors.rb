class AddKeepMeUpdatedToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :keep_me_updated, :boolean, default: true
    Distributor.update_all(keep_me_updated: true)
  end
end
