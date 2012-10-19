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
    @order.update_exclusions(params[:dislikes_input])
    @order.update_substitutions(params[:likes_input])

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

    respond_to do |format|
      if @order.pause!(start_date)
        date = @order.pause_date
        json = { id: @order.id, date: date, formatted_date: date.to_s(:pause), resume_dates: @order.possible_resume_dates }
        format.json { render json: json }
      else
        format.json { head :bad_request }
      end
    end
  end

  def remove_pause
    respond_to do |format|
      if @order.remove_pause!
        format.json { head :ok }
      else
        format.json { head :bad_request }
      end
    end
  end

  def pause_dates
    render json: @order.possible_pause_dates
  end

  def resume
    start_date = @order.pause_date
    end_date   = Date.parse(params[:date])

    respond_to do |format|
      if @order.pause!(start_date, end_date)
        date = @order.resume_date
        json = { id: @order.id, date: date, formatted_date: date.to_s(:pause) }
        format.json { render json: json }
      else
        format.json { head :bad_request }
      end
    end
  end

  def remove_resume
    start_date = @order.pause_date

    respond_to do |format|
      if @order.pause!(start_date)
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

  def filter_params
    params[:order] = params[:order].slice!(:include_extras)
  end

  def get_order
    @order = Order.find(params[:id])
  end

  def load_form
    @customer = current_customer
    @account  = @customer.account
    @route    = @customer.route
    @stock_list    = current_customer.distributor.line_items
    @form_params   = [:customer, @order]
    @dislikes_list = @order.exclusions.map { |e| e.line_item_id.to_s }
    @likes_list    = @order.substitutions.map { |s| s.line_item_id.to_s }
  end
end
