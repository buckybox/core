class AddExtrasLimitToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :extras_limit, :integer

  end
end
