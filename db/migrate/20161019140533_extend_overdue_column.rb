class ExtendOverdueColumn < ActiveRecord::Migration
  def change
    change_column :distributors, :overdue, :text, default: ''
  end
end
