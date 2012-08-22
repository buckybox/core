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
    @order = Order.find(params[:id])

    start_date = Date.parse(params[:date])
    end_date   = start_date + 366.days

    respond_to do |format|
      if @order.pause!(start_date, end_date)
        format.json { render json: { id: params[:id], formatted_date: start_date.to_s(:pause) } }
      else
        format.json { head :bad_request }
      end
    end
  end

  def remove_pause
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.remove_pause!
        format.json { head :ok }
      else
        format.json { head :bad_request }
      end
    end
  end

  def resume
    @order = Order.find(params[:id])

    start_date = @order.schedule.exception_times.first.to_date
    end_date   = Date.parse(params[:date])

    respond_to do |format|
      if @order.pause!(start_date, end_date)
        format.json { render json: { id: params[:id], formatted_date: (end_date + 1.day).to_s(:pause) } }
      else
        format.json { head :bad_request }
      end
    end
  end

  def remove_resume
    @order = Order.find(params[:id])

    start_date = @order.schedule.exception_times.first.to_date
    end_date   = start_date + 366.days

    respond_to do |format|
      if @order.pause!(start_date, end_date)
        format.json { head :ok }
      else
        format.json { head :bad_request }
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
