class Customer::OrdersController < Customer::ResourceController
  actions :new, :edit, :create, :update

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]

  def filter_params
    params[:order] = params[:order].slice!(:include_extras)
  end

  def new
    new! do
      @stock_list    = current_customer.distributor.line_items
      @dislikes_list = nil
      @likes_list    = nil
      @form_params   = [:customer, @order]

      load_form
    end
  end

  def create
    @order           = Order.new(params[:order])
    @order.account   = current_customer.account
    @order.completed = true

    @order.create_schedule(params[:start_date], params[:order][:frequency], params[:days])

    create! do |success, failure|
      @order.update_exclusions(params[:dislikes_input])
      @order.update_substitutions(params[:likes_input])
      @order.save

      success.html { redirect_to customer_root_url }
      failure.html { render 'new' }
    end
  end

  def edit
    edit! do
      @stock_list    = current_customer.distributor.line_items
      @dislikes_list = @order.exclusions.map { |e| e.line_item_id.to_s }
      @likes_list    = @order.substitutions.map { |s| s.line_item_id.to_s }
      @form_params   = [:customer, @order]

      load_form
    end
  end

  def update
    @order = current_customer.orders.find(params[:id])
    @order.update_exclusions(params[:dislikes_input])
    @order.update_substitutions(params[:likes_input])

    update! do |success, failure|
      success.html { redirect_to customer_root_url }
      failure.html { render 'edit' }
    end
  end

  def pause
    @order     = Order.find(params[:id])
    start_date = Date.parse(params['start_date'])
    end_date   = Date.parse(params['end_date'])

    redirect_to customer_root_url, warning: 'Dates can not be in the past' and return if start_date.past? || end_date.past?
    redirect_to customer_root_url, warning: 'Start date can not be past end date' and return if end_date <= start_date

    respond_to do |format|
      if @order.pause(start_date, end_date)
        format.html { redirect_to customer_root_path, notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, flash: {error: 'There was a problem pausing your order.'} }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_pause
    @order   = Order.find(params[:id])
    schedule = @order.schedule

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to customer_root_url, notice: 'Pause successfully removed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_url, flash: {error: 'There was a problem removing the pause from your order.'} }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def collection
    @orders ||= end_of_association_chain.active
  end

  private

  def load_form
    @customer = current_customer
    @account  = @customer.account
    @route    = @customer.route
  end
end
