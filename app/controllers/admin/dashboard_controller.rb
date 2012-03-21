class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.limit(3)
    @cron_logs    = CronLog.limit(25)
  end
end
