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

    CronLog.log("Running metrics for Librato.")
    Metrics.calculate_and_push_to_librato

    Distributor.refresh_webstore_caches
  end

  def self.run_daily
    CronLog.where("created_at < ?", 1.year.ago).delete_all

    Distributor.where("last_seen_at < ?", 6.months.ago).map do |distributor|
      distributor.lock_access!(send_instructions: false)
    end

    metrics_count = Metrics.calculate_and_store
    CronLog.log("#{metrics_count} metrics calculated and stored.")

    CronLog.log("Running metrics for daily Munin graphs.")
    Metrics.calculate_and_store_for_munin_daily

    DataIntegrity.delay(
      # - server is using UTC TZ
      # - 1am to 2am UTC is the calmest window for us (little visits) --> +1
      # - houly jobs run at minute 0 and we don't want to run integrity tests at the same time in
      #   order to spread resource usage -> +.5
      run_at: DateTime.tomorrow + 1.5.hours,
      queue: "#{__FILE__}:#{__LINE__}",
    ).check_and_email
  end

  def self.run_weekly
    CronLog.log("Running metrics for weekly Munin graphs.")
    Metrics.calculate_and_store_for_munin_weekly
  end
end
