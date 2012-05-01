class AddArchivedExtrasToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :archived_extras, :text

  end
end
