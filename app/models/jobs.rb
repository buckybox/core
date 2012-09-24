class Jobs
  def self.run_all
    CronLog.log("Checking distributors for automatic daily list creation.")
    Distributor.create_daily_lists

    CronLog.log("Checking deliveries and packages for automatic completion.")
    Distributor.automate_completed_status

    CronLog.log("Checking orders, deactivating those without any more deliveries.")
    Order.deactivate_finished

    CronLog.log("Updating customers next_order cache")
    Customer.find_each do |c|
      CronLog.log("Customer(#{c.id}) next_order cache failed to update") unless c.update_next_occurrence
    end
  end
end
