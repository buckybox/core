class DismissAllOldEvents < ActiveRecord::Migration
  def up
    Event.update_all(dismissed: true)
  end

  def down
    # Data migration so once this happens the data is lost
  end
end
