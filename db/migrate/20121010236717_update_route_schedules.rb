class UpdateRouteSchedules < ActiveRecord::Migration
  def up
    Route.reset_column_information
    ScheduleRule.reset_column_information

    Route.all.each do |route|
      #Make route valid if it isn't
      route.update_column(:area_of_service, ".") if route.area_of_service.blank?
      route.update_column(:estimated_delivery_time, ".") if route.estimated_delivery_time.blank?

      day_booleans = [route.sunday, route.monday, route.tuesday, route.wednesday, route.thursday, route.friday, route.saturday]
      days = day_booleans.each_with_index.collect { |bool, index|
        bool ? ScheduleRule::DAYS[index] : nil
      }.compact

      route.distributor.use_local_time_zone do
        sr = ScheduleRule.weekly(route.created_at.to_date, days)
        sr.save!
        sr.update_column(:scheduleable_id, route.id)
        sr.update_column(:scheduleable_type, 'Route')
      end
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
      route.save(validate: false)
      schedule_rule.destroy
    end
  end
end
