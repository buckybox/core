class AddHiddenFlagToExtras < ActiveRecord::Migration
  def change
    add_column :extras, :hidden, :boolean, default: false
  end
end
