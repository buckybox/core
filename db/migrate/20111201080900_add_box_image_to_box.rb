class AddBoxImageToBox < ActiveRecord::Migration
  def change
    add_column :boxes, :box_image, :string
  end
end
