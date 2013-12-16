class Customer::OrdersController < Customer::ResourceController
  actions :edit, :update

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:update]
  before_filter :get_order, only: [:pause, :remove_pause, :resume, :remove_resume, :pause_dates, :resume_dates]

  def edit
    edit! do
      load_form
    end
  end

  def update
    @order = current_customer.orders.find(params[:id])

    update! do |success, failure|
      success.html { redirect_to customer_root_url }
      failure.html do
        load_form
        flash[:error] = 'There was a problem creating this order.'
        render 'edit'
      end
    end
  end

  def pause
    start_date = Date.parse(params[:date])

    @order.pause!(start_date, @order.resume_date)
    @order.customer.add_activity(current_customer, :order_pause, order: @order)
    render partial: 'customer/orders/details', locals: { order: @order }
  end

  def remove_pause
    @order.remove_pause!
    @order.customer.add_activity(current_customer, :order_remove_pause, order: @order)
    render partial: 'customer/orders/details', locals: { order: @order }
  end

  def pause_dates
    render json: @order.possible_pause_dates
  end

  def resume
    start_date = @order.pause_date
    end_date   = Date.parse(params[:date])

    @order.pause!(start_date, end_date)
    @order.customer.add_activity(current_customer, :order_resume, order: @order)
    render partial: 'customer/orders/details', locals: { order: @order }
  end

  def remove_resume
    start_date = @order.pause_date

    @order.pause!(start_date)
    @order.customer.add_activity(current_customer, :order_remove_resume, order: @order)
    render partial: 'customer/orders/details', locals: { order: @order }
  end

  def deactivate
    @order = current_customer.orders.find(params[:id])

    respond_to do |format|
      if !current_customer.can_deactivate_orders?
        format.html { redirect_to customer_root_path, notice: "You don't have permission to do this. Please contact #{current_customer.distributor.name}." }
      elsif !@order.recurs? && @order.has_yellow_deliveries?
        format.html {redirect_to customer_root_path, alert: 'We could not remove this order as the impending delivery is too late to cancel.'}
      elsif current_customer.can_deactivate_orders? && @order.update_attribute(:active, false)
        format.html do
          if @order.recurs? && @order.has_yellow_deliveries?
            flash[:alert] = 'WARNING: there is an impending delivery which is too late to cancel, however we have removed the order for future deliveries.'
          else
            flash[:notice] = 'Your order was successfully removed.'
          end
          redirect_to customer_root_path
        end
        #format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, warning: 'Error while trying to remove your order.' }
        #format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def collection
    @orders ||= end_of_association_chain.active
  end

  private

  def filter_params
    params[:order] = params[:order].slice!(:include_extras)
  end

  def get_order
    @order = Order.find(params[:id])
  end

  def load_form
    @customer         = current_customer
    @distributor      = current_customer.distributor
    @account          = @customer.account
    @delivery_service = @customer.delivery_service
    @stock_list       = @distributor.line_items
    @form_params      = [:customer, @order]
    @dislikes_list    = @order.exclusions.map { |e| e.line_item_id.to_s }
    @likes_list       = @order.substitutions.map { |s| s.line_item_id.to_s }
  end
end
