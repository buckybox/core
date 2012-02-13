class Distributor::OrdersController < Distributor::BaseController
  nested_belongs_to :distributor, :account
  actions :all, :except => [:index, :show, :destroy]

  respond_to :html, :xml, :json

  def create
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:account_id])
    @order = Order.new(params[:order])

    frequency = params[:order][:frequency]
    start_time = Date.parse(params[:start_date]).to_time
    schedule = IceCube::Schedule.new(start_time)

    if frequency == 'single'
      schedule.add_recurrence_time(start_time)
    else
      days_by_number = params[:days].values.map(&:to_i).sort
      weeks_between_deliveries = Order::FREQUENCY_HASH[frequency]

      recurrence_rule = IceCube::Rule.weekly(weeks_between_deliveries).day(*days_by_number)
      schedule.add_recurrence_rule(recurrence_rule)
    end

    @order.account = @account
    @order.schedule = schedule
    @order.completed = true

    create! { [current_distributor, @account.customer] }
  end

  def update
    @distributor = current_distributor
    @account = @distributor.accounts.find(params[:account_id])
    @order = @distributor.orders.find(params[:id])

    # Not allowing changes to the schedule at the moment
    # Will revisit when we have time to build a proper UI for it
    params[:order].delete(:frequency)

    update! { [current_distributor, @account.customer] }
  end

  def deactivate
    @distributor = Distributor.find(params[:distributor_id])
    @account = Account.find(params[:account_id])
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attribute(:active, false)
        format.html { redirect_to [current_distributor, @account.customer], notice: 'Order was successfully deactivated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [current_distributor, @account.customer], warning: 'Error while trying to deactivate order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def pause
    @distributor = Distributor.find(params[:distributor_id])
    @account     = Account.find(params[:account_id])
    @order       = Order.find(params[:id])

    start_date = Date.parse(params['start_date'])
    end_date   = Date.parse(params['end_date']) - 1.day

    schedule   = @order.schedule

    redirect_to [@distributor, @account.customer], warning: 'Dates can not be in the past' and return if start_date.past? || end_date.past?
    redirect_to [@distributor, @account.customer], warning: 'Start date can not be past end date' and return if end_date <= start_date

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }
    (start_date..end_date).each   { |date| schedule.add_exception_time(date.to_time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to [@distributor, @account.customer], notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [@distributor, @account.customer], error: 'There was a problem pausing your order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_pause
    @distributor = Distributor.find(params[:distributor_id])
    @account     = Account.find(params[:account_id])
    @order       = Order.find(params[:id])

    schedule   = @order.schedule

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to [@distributor, @account.customer], notice: 'Pause successfully removed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [@distributor, @account.customer], error: 'There was a problem removing the pause from your order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end
end
