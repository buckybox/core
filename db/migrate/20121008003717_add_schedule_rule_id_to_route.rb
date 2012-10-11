class AddScheduleRuleIdToRoute < ActiveRecord::Migration
  def up
    add_column :routes, :schedule_rule_id, :integer

    Route.reset_column_information
    Route.all.each do |route|
      #Make route valid if it isn't
      route.area_of_service ||= "."
      route.estimated_delivery_time ||= "."

      route.send(:create_schedule_rule)
      route.save!
    end

    remove_column :routes, :schedule
  end

  def down
    add_column :routes, :schedule, :text

    Route.reset_column_information
    Route.all.each do |route|
      schedule_rule = route.schedule_rule
      route.monday = schedule_rule.mon
      route.tuesday = schedule_rule.tue
      route.wednesday = schedule_rule.wed
      route.thursday = schedule_rule.thu
      route.friday = schedule_rule.fri
      route.saturday = schedule_rule.sat
      route.sunday = schedule_rule.sun

      route.schedule_rule = nil
      route.save!
      schedule_rule.destroy
    end

    remove_column :routes, :schedule_rule_id
  end
end
