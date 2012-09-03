class Admin::DistributorsController < Admin::ResourceController
  def index
    @distributors = Distributor.order('name')
    index!
  end

  def impersonate
    distributor = Distributor.find(params[:id])
    sign_in(distributor, bypass: true) # bypass means it won't update last logged in stats

    redirect_to distributor_root_url
  end

  def unimpersonate
    sign_out(:distributor)

    redirect_to admin_root_url
  end

  def customer_import
  end

  def validate_customer_import
    parse_csv

    @customer_data_fields = Bucky::Import::Customer::DATA_FIELDS + [:tags]
    @group_count = (@customer_data_fields.size / 3.0).ceil
    @order_data_fields = Bucky::Import::Box::DATA_FIELDS
  end

  def customer_import_upload
    parse_csv

    if @distributor.import_customers(@customers)
      redirect_to admin_root_url, notice: 'Customers successfully added'
    else
      flash[:error] = 'There was a problem, no customers were added. Please let Jordan or Samson know.'
      render :validate_customer_import
    end
  end

  def invoice
    @distributor = Distributor.find(params[:id])

    render json: @distributor.invoice_for_range(params[:start_date], params[:end_date])
  end

  private

  def parse_csv
    @distributor = Distributor.find(params[:id])
    csv = params[:customer_import][:csv].read

    @customers = Bucky::Import.parse(csv, @distributor)
  end
end
