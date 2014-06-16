class Admin::DistributorsController < Admin::ResourceController

  before_filter :parameterize_name, only: [:create, :update]

  def index
    @distributors = Distributor.scoped
    @distributors = @distributors.tagged_with(params[:tag]) if params[:tag].present?
    @distributors = @distributors.sort { |a,b| b.orders.active.size <=> a.orders.active.size }
    index!
  end

  def create
    create! do |success, failure|
      success.html do
        Distributor::Defaults.populate_defaults(@distributor)
        redirect_to admin_distributor_path(@distributor)
      end
    end
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

  def country_setting
    @country = Country.find(params[:id])

    time_zone = ActiveSupport::TimeZone::MAPPING.find do |_, city|
      city == @country.time_zone
    end
    time_zone = time_zone.first if time_zone

    render json: {
      time_zone: time_zone,
      currency: @country.currency,
      fee: @country.default_consumer_fee_cents / 100.0
    }
  end

private

  def parameterize_name
    if params[:distributor]
      parameterized_name = Distributor.parameterize_name(params[:distributor][:parameter_name])
      params[:distributor][:parameter_name] = parameterized_name
    end
  end

  def parse_csv
    @distributor = Distributor.find(params[:id])
    csv = params[:customer_import][:csv].read

    @customers = Bucky::Import.parse(csv, @distributor)
  end
end
