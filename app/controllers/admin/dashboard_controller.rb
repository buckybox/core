class Admin::DashboardController < Admin::BaseController
  def index
    @demo_distributor = Distributor.demo

    @distributors = Distributor.active

    @customer_count = Rails.cache.fetch('admin.total_active_transactional_customer_count', expires_in: 1.day) do
      @distributors.map(&:transactional_customer_count).sum
    end

    @cron_logs = CronLog.limit(10)
  end
end
