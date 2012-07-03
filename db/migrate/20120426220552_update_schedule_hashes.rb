class UpdateScheduleHashes < ActiveRecord::Migration
  class Distributor < ActiveRecord::Base; end
  class Customer < ActiveRecord::Base; end
  class Account < ActiveRecord::Base; end
  class Order < ActiveRecord::Base; end
  class Route < ActiveRecord::Base; end

  def up
    Distributor.reset_column_information
    Customer.reset_column_information
    Account.reset_column_information
    Order.reset_column_information
    Route.reset_column_information

    Order.all.each do |order|
      account_id     = order.read_attribute(:account_id)
      account        = Account.find_by_id(account_id)
      customer_id    = account.read_attribute(:customer_id) if account
      customer       = Customer.find_by_id(customer_id)
      distributor_id = customer.read_attribute(:distributor_id) if customer
      distributor    = Distributor.find_by_id(distributor_id)


      convert_schedule_days_to_utc(order, distributor)
    end

    Route.all.each do |route|
      customer_id    = route.read_attribute(:customer_id)
      customer       = Customer.find_by_id(customer_id)
      distributor_id = customer.read_attribute(:distributor_id) if customer
      distributor    = Distributor.find_by_id(distributor_id)

      convert_schedule_days_to_utc(route, distributor)
    end
  end

  def down
    # Could roll back this data but not worth it
  end

  private

  def convert_schedule_days_to_utc(object, distributor)
    if distributor
      time_zone  = distributor.read_attribute(:time_zone)
      Time.zone  = time_zone if time_zone
      before_utc = (Time.zone.utc_offset > 0)
    end

    schedule_hash  = YAML::load(object.read_attribute(:schedule))
    schedule_rules = schedule_hash[:rrules] if schedule_hash

    # Only need to convert rules as time are already stored in UTC time
    if !schedule_rules.blank?
      schedule_rules.each_with_index do |schedule_rule, index|
        rule_type = schedule_rule[:rule_type]

        if rule_type == 'IceCube::WeeklyRule'
          day_array = schedule_rule[:validations][:day]
          utc_day_array = day_array.map { |day| (day - 1) % 7 }

          schedule_hash[:rrules][index][:validations][:day] = utc_day_array
        elsif rule_type == 'IceCube::MonthlyRule'
          day_hash = schedule_rule[:validations][:day_of_week]
          utc_day_hash = day_hash.inject({}) { |h,(k,v)| h[(k - 1) % 7] = v; h }

          schedule_hash[:rrules][index][:validations][:day_of_week] = utc_day_hash
        end
      end

      object.update_attribute(:schedule, schedule_hash.to_yaml)
    end
  end
end
