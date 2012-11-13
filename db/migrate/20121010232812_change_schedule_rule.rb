class ChangeScheduleRule < ActiveRecord::Migration
  def up
    add_column :schedule_rules, :scheduleable_id, :integer
    add_column :schedule_rules, :scheduleable_type, :string

    ScheduleRule.reset_column_information
    ScheduleRule.find_each do |schedule_rule|
      if schedule_rule.order_id.present?
        order = Order.find(schedule_rule.order_id)
        schedule_rule.scheduleable = order
        schedule_rule.save!
      else
        raise "Couldn't find order or route for schedule_rule: #{schedule_rule.inspect}"
      end
    end

    remove_column :schedule_rules, :order_id
  end

  def down
    add_column :schedule_rules, :order_id, :integer
    
    ScheduleRule.reset_column_information
    Route.reset_column_information

    ScheduleRule.find_each do |schedule_rule|
      if schedule_rule.scheduleable.is_a?(Order)
        schedule_rule.order_id = schedule_rule.scheduleable_id
        schedule_rule.save!
      else
        raise "Scheduleable wasn't a route or order"
      end
    end

    remove_column :schedule_rules, :scheduleable_id
    remove_column :schedule_rules, :scheduleable_type
  end
end
