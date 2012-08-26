class Distributor::OrdersController < Distributor::ResourceController
  belongs_to :account
  actions :all, except: [:index, :show, :destroy]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]
  before_filter :get_order, only: [:pause, :remove_pause, :resume, :remove_resume, :pause_dates, :resume_dates]

  def filter_params
    params[:order] = params[:order].slice!(:include_extras)
  end

  def new
    new! do
      @stock_list    = current_distributor.line_items
      @dislikes_list = nil
      @likes_list    = nil
      @form_params   = [:distributor, @account, @order]

      load_form
    end
  end

  def create
    @account = current_distributor.accounts.find(params[:account_id])

    load_form

    order_hash = params[:order]
    order_hash.merge!({account_id: @account.id, completed: true})

    @order = Order.new(order_hash)

    @order.create_schedule(params[:start_date], params[:order][:frequency], params[:days])

    create!  do |success, failure|
      @order.update_exclusions(params[:dislikes_input])
      @order.update_substitutions(params[:likes_input])
      @order.save

      success.html { redirect_to [:distributor, @account.customer] }
      failure.html { render 'new' }
    end
  end

  def edit
    edit! do
      @stock_list    = current_distributor.line_items
      @dislikes_list = @order.exclusions.map { |e| e.line_item_id.to_s }
      @likes_list    = @order.substitutions.map { |s| s.line_item_id.to_s }
      @form_params   = [:distributor, @account, @order]

      load_form
    end
  end

  def update
    @account = current_distributor.accounts.find(params[:account_id])
    @order   = current_distributor.orders.find(params[:id])

    @order.update_exclusions(params[:dislikes_input])
    @order.update_substitutions(params[:likes_input])

    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update!  do |success, failure|
      success.html { redirect_to [:distributor, @account.customer] }
      failure.html { render 'edit' }
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
    end_date   = Bucky::Schedule.until_further_notice(start_date)

    respond_to do |format|
      if @order.pause!(start_date, end_date)
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
    start_date = @order.schedule.exception_times.first.to_date
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
    start_date = @order.schedule.exception_times.first.to_date
    end_date   = Bucky::Schedule.until_further_notice(start_date)

    respond_to do |format|
      if @order.pause!(start_date, end_date)
        format.json { head :ok }
      else
        format.json { head :bad_request }
      end
    end
  end

  def resume_dates
    render json: @order.possible_resume_dates
  end

  private

  def get_order
    @order = Order.find(params[:id])
  end

  def load_form
    @customer = @account.customer
    @route    = @customer.route
  end
end
