class AddNotesToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :notes, :text
  end
end
