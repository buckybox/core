class Distributor::OrdersController < Distributor::ResourceController
  belongs_to :account
  actions :all, except: [:index, :show, :destroy]

  respond_to :html, :xml, :json

  before_filter :filter_params, only: [:create, :update]

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
    order_hash.merge!({ account_id: @account.id, completed: true })

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
    @account = Account.find(params[:account_id])
    @order   = Order.find(params[:id])

    start_date = Date.parse(params['start_date'])
    end_date   = Date.parse(params['end_date'])

    redirect_to [:distributor, @account.customer], error: 'Dates can not be in the past' and return if start_date.past? || end_date.past?
    redirect_to [:distributor, @account.customer], error: 'Start date can not be past end date' and return if end_date <= start_date

    respond_to do |format|
      if @order.pause(start_date, end_date)
        format.html { redirect_to [:distributor, @account.customer], notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [:distributor, @account.customer], flash: { error: 'There was a problem pausing your order.' } }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_pause
    @account = Account.find(params[:account_id])
    @order   = Order.find(params[:id])

    schedule = @order.schedule

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to [:distributor, @account.customer], notice: 'Pause successfully removed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [:distributor, @account.customer], flash: {error: 'There was a problem removing the pause from your order.'} }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_form
    @customer = @account.customer
    @route    = @customer.route
  end
end
