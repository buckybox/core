class Admin::DashboardController < Admin::BaseController
  def index
    @demo_distributor = Distributor.demo
    @distributors = Distributor.active
    @customer_count = Customer.active_count
    @cron_logs = CronLog.limit(10)
  end
end
