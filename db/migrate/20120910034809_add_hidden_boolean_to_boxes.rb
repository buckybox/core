class AddHiddenBooleanToBoxes < ActiveRecord::Migration
  def change
    add_column :boxes, :hidden, :boolean, default: false, null: false
  end
end
