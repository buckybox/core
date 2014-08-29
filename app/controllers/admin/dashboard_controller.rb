class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.active

    demo = Distributor.find_by(email: "demo@buckybox.com")
    @distributors = [demo] | @distributors if demo

    @cron_logs = CronLog.limit(10)
  end
end
