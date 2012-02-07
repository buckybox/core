class AddTriggerDateToEvent < ActiveRecord::Migration
  def change
    add_column :events, :trigger_on, :datetime
  end
end
