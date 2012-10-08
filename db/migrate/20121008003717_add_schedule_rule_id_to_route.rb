class AddScheduleRuleIdToRoute < ActiveRecord::Migration
  def change
    add_column :routes, :schedule_rule_id, :integer

    Route.reset_column_information
    Route.all.each do |route|
      
    end
  end
end
