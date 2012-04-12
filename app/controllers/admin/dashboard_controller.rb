class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.limit(5)
    @cron_logs    = CronLog.limit(25)
  end
end
