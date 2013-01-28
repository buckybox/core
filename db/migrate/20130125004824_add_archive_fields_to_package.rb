class AddArchiveFieldsToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :archived_substitutions, :string
    add_column :packages, :archived_exclusions, :string
    add_column :packages, :archived_address_details, :text
  end
end
