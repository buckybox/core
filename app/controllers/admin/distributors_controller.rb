class Admin::DistributorsController < Admin::ResourceController

  before_filter :parameterize_name, only: [:create, :update]

  def index
    @distributors = Distributor.scoped
    @distributors = @distributors.tagged_with(params[:tag]) if params[:tag].present?
    @distributors = @distributors.sort { |a,b| b.orders.active.size <=> a.orders.active.size }
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

  def country_setting
    @country = Country.find(params[:id])

    render json: {
      time_zone: ActiveSupport::TimeZone::MAPPING.invert[@country.default_time_zone],
      currency: Money.parse(@country.default_currency).currency.id.upcase,
      fee: @country.default_consumer_fee_cents / 100.0
    }
  end

  def invoice
    @distributor = Distributor.find(params[:id])

    render json: @distributor.invoice_for_range(params[:start_date], params[:end_date])
  end

  def reset_intros
    @distributor = Distributor.find(params[:id])

    intro_tour_columns = Distributor.column_names.select { |name| name =~ /_intro$/ }
    intro_tour_columns = intro_tour_columns.each_with_object({}) { |column, hash| hash[column] = true }

    if @distributor.update_attributes(intro_tour_columns)
      flash[:notice] = "The intro tours have been reset for #{@distributor.name}"
    else
      flash[:error] = "There was some weird error in resetting the intro tours for #{@distributor.name}."
    end

    redirect_to :back
  end

  def write_email
    @email = EmailForm.new(preview_email: current_admin.email)
  end

  def send_email
    @email = EmailForm.new(params[:email_form])
    if params[:commit] == 'Send' && @email.send!
      flash.now[:notice] = 'Emails queued for delivery.'
      @sent = true
    elsif @email.send_preview!
      flash.now[:notice] = "Preview email sent to #{@email.preview_email}."
      @sent = false
    else
      flash.now[:alert] = "Email could not be sent. #{@email.errors.full_messages.join(', ')}"
      @sent = false
    end

    render :write_email
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
