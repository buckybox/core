class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.limit(3)
    @cron_logs    = CronLog.limit(25)
  end

  def customer_import
  end

  def validate_customer_import
    @distributor = Distributor.find(params[:id])
    csv = params[:customer_import][:csv].read

    @customers = Bucky::Import.parse(csv, @distributor)
  end

  def customer_import_upload

  end
end
