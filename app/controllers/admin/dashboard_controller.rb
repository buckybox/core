class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.
      where("current_sign_in_at > ?", 1.month.ago).
      select { |d| d.transactional_customer_count > 10}.
      sort_by(&:transactional_customer_count).reverse

    @cron_logs = CronLog.limit(10)
  end
end
