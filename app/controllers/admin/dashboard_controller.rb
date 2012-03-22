class Admin::DashboardController < Admin::BaseController
  def index
    @distributors = Distributor.limit(3)
    @cron_logs    = CronLog.limit(25)
  end

  def customer_import
  end

  def validate_customer_import
    parse_csv
  end

  def customer_import_upload
    parse_csv
    if @distributor.import_customers(@customers)
      redirect_to admin_root_url, notice: "Customers successfully added"
    else
      flash[:error] = "There was a problem, no customers were added.  Please let Jordan or Samson know."
      render :validate_customer_import
    end
  end

  def parse_csv
    @distributor = Distributor.find(params[:id])
    csv = params[:customer_import][:csv].read

    @customers = Bucky::Import.parse(csv, @distributor)
  end
end
