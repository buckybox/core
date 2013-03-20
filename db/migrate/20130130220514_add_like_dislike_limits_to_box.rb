class AddLikeDislikeLimitsToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :exclusions_limit, :integer, default: 0
    add_column :boxes, :substitutions_limit, :integer, default: 0
    Box.update_all("exclusions_limit = 0, substitutions_limit = 0")
  end
end
