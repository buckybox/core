class AddRequirePostCodeToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :require_post_code, :boolean, null: false, default: false
  end
end
