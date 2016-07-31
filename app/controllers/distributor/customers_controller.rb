class Distributor::CustomersController < Distributor::ResourceController
  respond_to :html, :json

  before_action :check_setup, only: [:index]
  before_action :get_email_templates, only: [:index, :show]

  def index
    index! do
      @show_tour = current_distributor.customers_index_intro

      balance = CrazyMoney.new(@customers.joins(:account).sum(:balance_cents)) / 100
      @customers_total_balance = balance.with_currency(current_distributor.currency)
    end
  end

  def new
    locals = { new_customer: Distributor::Form::NewCustomer.new(pre_form_args) }
    render "new", locals: locals
  end

  # just update customer notes
  def update
    customer = current_distributor.customers.find(params[:id])

    if customer.update_attributes(notes: params[:customer][:notes])
      flash[:notice] = "The customer notes have been successfully updated."
    else
      flash[:error] = "Oops, there was an issue updating the customer notes."
    end

    redirect_to distributor_customer_url(customer)
  end

  def destroy
    customer = current_distributor.customers.find(params[:id])

    # NOTE: don't delete everything, e.g. we want to keep deductions for billing
    customer.account.orders.map(&:order_extras).flatten.map(&:delete)
    customer.account.orders.map(&:packages).flatten.map(&:delete)
    customer.account.orders.delete_all
    customer.account.delete
    customer.address.delete
    customer.delete

    redirect_to distributor_customers_url, notice: "The customer has been deleted."
  end

  def edit_profile
    locals = { customer_profile: Distributor::Form::EditCustomerProfile.new(pre_form_args) }
    render "edit_profile", locals: locals
  end

  def edit_delivery_details
    locals = { delivery_details: Distributor::Form::EditCustomerDeliveryDetails.new(pre_form_args) }
    render "edit_delivery_details", locals: locals
  end

  def create
    args   = form_args(:distributor_form_new_customer)
    form   = Distributor::Form::NewCustomer.new(args)
    locals = { new_customer: form }
    tracking.event(current_distributor, "new_customer") if form.save && !current_admin.present?
    form.save ? successful_create(form) : failed_form_submission(form, "new", locals)
  end

  def update_profile
    args   = form_args(:distributor_form_edit_customer_profile)
    form   = Distributor::Form::EditCustomerProfile.new(args)
    locals = { customer_profile: form }
    form.save ? successful_update(form, "profile") : failed_form_submission(form, "edit_profile", locals)
  end

  def update_delivery_details
    args   = form_args(:distributor_form_edit_customer_delivery_details)
    form   = Distributor::Form::EditCustomerDeliveryDetails.new(args)
    locals = { delivery_details: form }
    form.save ? successful_update(form, "delivery details") : failed_form_submission(form, "edit_delivery_details", locals)
  end

  def show
    @customer         = current_distributor.customers.find(params[:id])
    @address          = @customer.address
    @account          = @customer.account.decorate
    @orders           = @account.orders.active.decorate
    @deliveries       = @account.deliveries.ordered
    @transactions     = account_transactions(@account)
    @show_more_link   = (@transactions.size != @account.transactions.count)
    @transactions_sum = @account.calculate_balance
    @show_tour        = current_distributor.customers_show_intro
  end

  def send_login_details
    @customer = current_distributor.customers.find(params[:id])

    @customer.randomize_password
    @customer.save

    CustomerMailer.raise_errors do
      if @customer.send_login_details
        flash[:notice] = "Login details successfully sent"
      else
        flash[:error] = "Sending emails is disabled, login details not sent"
      end
    end

    tracking.event(current_distributor, "sent_login_details") unless current_admin.present?

    redirect_to distributor_customer_url(@customer)
  end

  def email
    link_action = params[:link_action]
    link_action = "send" if link_action.empty?

    message = if link_action == "delete"
      email_templates_update(link_action)

    else
      return error("Oops") unless params[:email_template]

      email_template = EmailTemplate.new(
        params[:email_template][:subject],
        params[:email_template][:body]
      )

      return error(email_template.errors.join('<br>')) unless email_template.valid?

      email_templates_update(link_action, email_template)
    end

    if message && current_distributor.save
      flash[:notice] = message if link_action == "send"
      render json: { link_action => true, message: message }
    else
      return error(current_distributor.errors.full_messages)
    end
  end

  def export
    recipient_ids = params[:export][:recipient_ids].split(',').map(&:to_i)
    csv_string    = CustomerCSV.generate(current_distributor, recipient_ids)

    tracking.event(current_distributor, "export_csv_customer_list") unless current_admin.present?

    send_csv("customer_export", csv_string)
  end

  def impersonate
    customer = current_distributor.customers.find(params[:id])
    sign_in(customer, bypass: true) # bypass means it won't update last logged in stats

    redirect_to customer_root_path
  end

  def activity
    customer = current_distributor.customers.find(params[:id])

    render partial: "activity", locals: { activities: customer.recent_activities }
  end

protected

  def collection
    @customers = end_of_association_chain

    if params[:query].present?
      query = params[:query].delete('.')
      @customers = if params[:query].to_i.zero?
        current_distributor.customers.search(query)
      else
        current_distributor.customers.where(number: query.to_i)
      end

      tracking.event(current_distributor, "search_customer_list") unless current_admin.present?
    end

    if (tag = params[:tag]).present?
      @customers = @customers.tagged_with(tag) unless tag.in?(CustomerDecorator.all_dynamic_tags_as_a_list)
    end

    @customers = @customers.ordered_by_next_delivery.includes(
      :tags,
      account: [:delivery_service],
      next_order: [:box]
    )

    if tag.in?(Customer.all_dynamic_tags_as_a_list)
      ids = @customers.select { |customer| tag.in?(customer.dynamic_tags) }.map(&:id)
      @customers = Customer.where(id: ids)
    end
  end

private

  def form_args(param_key)
    pre_form_args.merge(params[param_key] || {})
  end

  def pre_form_args
    customer = current_distributor.customers.find_by(id: params[:id]) || Customer.new
    { distributor: current_distributor, customer: customer }
  end

  def successful_create(form)
    notice = "The customer have been successfully created."
    successful_form_submission(form, notice)
  end

  def successful_update(form, submitted_changes)
    notice = "The customer #{submitted_changes} have been successfully updated."
    successful_form_submission(form, notice)
  end

  def successful_form_submission(form, notice)
    flash[:notice] = notice
    redirect_to distributor_customer_url(form.customer)
  end

  def failed_form_submission(form, action, locals)
    flash[:alert] = "Oops there was an issue: #{formatted_error_messages(form)}"
    render action, locals: locals
  end

  def formatted_error_messages(form)
    form.errors.full_messages.join(", ").downcase
  end

  def error(message)
    render json: { message: message }, status: :unprocessable_entity
  end

  def email_templates_update(action, email_template = nil)
    selected_email_template_id = params[:selected_email_template_id].to_i
    recipient_ids = params[:recipient_ids].split(',').map(&:to_i)
    message = nil

    case action
    when "update"
      current_distributor.email_templates[selected_email_template_id] = email_template
      message = "Your changes have been saved."

    when "delete"
      deleted = current_distributor.email_templates.delete_at(selected_email_template_id)
      message = "Email template <em>#{deleted.subject}</em> has been deleted."

    when "save"
      current_distributor.email_templates << email_template
      message = "Your new email template <em>#{email_template.subject}</em> has been saved."

    when "preview"
      customer = current_distributor.customers.find recipient_ids.first
      personalized_email = email_template.personalize(customer)
      CustomerMailer.email_template(current_distributor, personalized_email).deliver
      message = "A preview email has been sent to #{current_distributor.email}."

    when "send"
      if params[:commit]
        message = send_email recipient_ids, email_template

        tracking.event(current_distributor, "sent_group_email") unless current_admin.present?
      end
    end

    message
  end

  def send_email(recipient_ids, email)
    recipient_ids.each do |id|
      customer = current_distributor.customers.find id
      personalized_email = email.personalize(customer)

      CustomerMailer.delay(
        priority: Figaro.env.delayed_job_priority_high,
        queue: "#{__FILE__}:#{__LINE__}",
      ).email_template(customer, personalized_email)
    end

    message = "Your email \"#{email.subject}\" is being sent to "
    message << if recipient_ids.size == 1
      current_distributor.customers.find(recipient_ids.first).name
    else
      "#{recipient_ids.size} customers"
    end
    message << "..."
  end
end
