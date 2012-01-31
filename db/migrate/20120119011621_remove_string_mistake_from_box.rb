class RemoveStringMistakeFromBox < ActiveRecord::Migration
  def up
    remove_column :boxes, :string
  end

  def down
    add_column :boxes, :string, :string
  end
end
