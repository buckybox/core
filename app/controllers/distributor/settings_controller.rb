class Distributor::SettingsController < Distributor::BaseController
  respond_to :html, :json

  before_filter :catch_cancel

  def business_information
    time = Time.new
    @default_delivery_time  = Time.new(time.year, time.month, time.day, current_distributor.advance_hour)
    @default_delivery_days  = current_distributor.advance_days
    @default_automatic_time = Time.new(time.year, time.month, time.day, current_distributor.automatic_delivery_hour)
  end
  
  def webstore(form = SettingsWebstoreForm.for_distributor(current_distributor))
    @form = form
    render :webstore
  end

  def save_webstore
    form = SettingsWebstoreForm.new(params[:settings_webstore_form])

    if form.save(current_distributor)
      redirect_to distributor_settings_webstore_path, notice: "Webstore settings were successfully saved."
    else
      webstore(form)
    end
  end

  def spend_limit_confirmation
    spend_limit = BigDecimal.new(params[:spend_limit]) * BigDecimal.new(100)
    update_existing = params[:update_existing] == '1'
    send_halt_email = params[:send_halt_email] == '1'
    count = current_distributor.number_of_customers_halted_after_update(spend_limit, update_existing)
    if count > 0
      count_emailed = current_distributor.number_of_customers_emailed_after_update(spend_limit, update_existing)
      render text: "Updating the minimum balance will halt #{count} customers deliveries.  #{count_emailed.to_s + " customers with pending orders will be emailed that their account has been halted until payment is made.  " if count_emailed > 0 && send_halt_email && current_distributor.send_email? }Are you sure?"
    else
      render text: "safe"
    end
  end

  def delivery_services
    @delivery_service = DeliveryService.new
    @delivery_services = current_distributor.delivery_services.decorate
  end

  def extras
    @extra = Extra.new
    @extras = current_distributor.extras.alphabetically.decorate
  end

  def boxes
    @box = Box.new
    @boxes = current_distributor.boxes.decorate
  end

  def invoice_information
    @invoice_information = current_distributor.invoice_information || InvoiceInformation.new
  end

  def customer_preferences
    @edit_mode = params[:edit] || false

    @line_items = current_distributor.line_items
    @placeholder_text = 'Enter items one per line or separated by commas. e.g. Silverbeet, Cabbage, Celery'
  end

  def catch_cancel
    redirect_to :back if params[:commit] == 'cancel'
  end
end
