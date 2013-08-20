class Distributor::OrdersController < Distributor::ResourceController
  belongs_to :account
  actions :all, except: [:index, :show, :destroy]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]
  before_filter :get_order, only: [:pause, :remove_pause, :resume, :remove_resume, :pause_dates, :resume_dates]

  before_filter :check_for_boxes, only: [:new]

  def new
    new! do
      load_form
    end
  end

  def create
    @account = current_distributor.accounts.find(params[:account_id])

    order_hash = params[:order]
    order_hash.merge!({ account_id: @account.id, completed: true })

    @order = Order.new(order_hash)

    create!  do |success, failure|
      success.html do
        tracking.event(current_distributor, "new_order")
        redirect_to [:distributor, @account.customer]
      end

      failure.html do
        load_form
        flash[:error] = 'There was a problem creating this order.'
        render 'new'
      end
    end
  end

  def edit
    edit! do
      load_form
    end
  end

  def update
    @account = current_distributor.accounts.find(params[:account_id])
    @order   = current_distributor.orders.find(params[:id])

    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update!  do |success, failure|
      success.html { redirect_to [:distributor, @account.customer] }
      failure.html do
        load_form
        flash[:error] = 'There was a problem creating this order.'
        render 'edit'
      end
    end
  end

  def deactivate
    @account = Account.find(params[:account_id])
    @order   = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attribute(:active, false)
        format.html { redirect_to [:distributor, @account.customer], notice: 'Order was successfully deactivated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [:distributor, @account.customer], warning: 'Error while trying to deactivate order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def pause
    start_date = Date.parse(params[:date])

    @order.pause!(start_date, @order.resume_date)
    render partial: 'distributor/orders/details', locals: { order: @order }
  end

  def remove_pause
    @order.remove_pause!
    render partial: 'distributor/orders/details', locals: { order: @order }
  end

  def pause_dates
    render json: @order.possible_pause_dates
  end

  def resume
    start_date = @order.pause_date
    end_date   = Date.parse(params[:date])

    @order.pause!(start_date, end_date)
    render partial: 'distributor/orders/details', locals: { order: @order }
  end

  def remove_resume
    start_date = @order.pause_date

    @order.pause!(start_date)
    render partial: 'distributor/orders/details', locals: { order: @order }
  end
  
  private

  def check_for_boxes
    redirect_to distributor_settings_boxes_path, alert: "You must create a box before creating any orders." if current_distributor.boxes.count.zero?
  end

  def filter_params
    params[:order] = params[:order].slice!(:include_extras)
  end

  def get_order
    @order = Order.find(params[:id])
  end

  def load_form
    @customer      = @account.customer
    @route         = @customer.route
    @stock_list    = current_distributor.line_items
    @form_params   = [:distributor, @account, @order]
    @dislikes_list = @order.exclusions.map { |e| e.line_item_id.to_s }
    @likes_list    = @order.substitutions.map { |s| s.line_item_id.to_s }
  end
end
