class Jobs
  def self.run_hourly
    CronLog.log("Checking distributors for automatic daily list creation.")
    Distributor.create_daily_lists

    CronLog.log("Checking deliveries and packages for automatic completion.")
    Distributor.automate_completed_status

    CronLog.log("Checking orders, deactivating those without any more deliveries.")
    Order.deactivate_finished

    CronLog.log("Checking distributors if next order cache needs updating.")
    Distributor.update_next_occurrence_caches

    CronLog.log("Running metrics for Munin graphs.")
    Metrics.calculate_and_store_for_munin
  end

  def self.run_daily
    CronLog.log("Running metrics.")
    count = Metrics.calculate_and_store
    CronLog.log("#{count} metrics calculated and stored.")

    CronLog.log("Running data integrity tests.")
    DataIntegrity.check_and_email
  end
end
