class UpdateNewColumnsToHaveDefaults < ActiveRecord::Migration
  def up
    Box.update_all({extras_limit: 0}, {extras_limit: nil})
    Package.update_all({archived_extras: [].to_yaml}, {archived_extras:nil})
    change_column :boxes, :extras_limit, :integer, default: 0
  end

  def down
  end
end
