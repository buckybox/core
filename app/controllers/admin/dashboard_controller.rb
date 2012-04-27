class Admin::DashboardController < Admin::BaseController
  def index
    # OPTIMIZE: This should be done with some sort of Arel magic or something (NOT SQL) but this works for now.
    @distributors = Distributor.all.sort { |a,b| b.orders.size <=> a.orders.size }[0..5]
    @cron_logs    = CronLog.limit(25)
  end
end
