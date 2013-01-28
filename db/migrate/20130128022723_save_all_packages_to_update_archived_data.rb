class SaveAllPackagesToUpdateArchivedData < ActiveRecord::Migration
  def up
    Package.unpacked.all.map(&:save)
  end

  def down
  end
end
