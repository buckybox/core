class Admin::DashboardController < Admin::BaseController
  def index
    # OPTIMIZE: This should be done with some sort of Arel magic or something (NOT SQL) but this works for now.
    @distributors = Distributor.all.sort { |a,b| b.orders.active.size <=> a.orders.active.size }[0..15]
    @cron_logs    = CronLog.limit(5)
  end
end
