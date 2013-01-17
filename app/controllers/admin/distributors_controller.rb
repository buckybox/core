class Admin::DistributorsController < Admin::ResourceController

  before_filter :parameterize_name, only: [:create, :update]

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

  def country_setting
    @country = Country.find(params[:id])

    render json: {time_zone: ActiveSupport::TimeZone.new(@country.default_time_zone).name,
                  currency: Money.parse(@country.default_currency).currency.id.upcase,
                  fee: @country.default_consumer_fee_cents / 100.0}
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

  def spend_limit_confirmation
    distributor = Distributor.find(params[:form_id].split('_').last.to_i)
    spend_limit = params[:spend_limit].to_f * 100.0
    update_existing = params[:update_existing] == '1'
    send_halt_email = params[:send_halt_email] == '1'
    count = distributor.number_of_customers_halted_after_update(spend_limit, update_existing)
    if count > 0
      render text: "Updating the spend limit will halt #{count} customers deliveries.  #{"They will be emailed that their account has been halted until payment is made.  " if send_halt_email && current_distributor.send_email? }Are you sure?"
    else
      render text: "safe"
    end
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
