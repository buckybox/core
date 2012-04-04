class Customer::OrdersController < Customer::ResourceController
  actions :new, :create, :update

  respond_to :html, :xml, :json

  def update
    update! do |success, failure|
      success.html { redirect_to customer_root_url }
      failure.html { redirect_to customer_root_url }
    end
  end

  def create
    @order           = Order.new(params[:order])
    @order.account   = current_customer.account
    @order.completed = true

    if params[:start_date] && params[:days]
      frequency        = params[:order][:frequency]
      start_time       = Date.parse(params[:start_date]).to_time
      days_by_number   = params[:days].values.map(&:to_i).sort unless frequency == 'single'

      @order.create_schedule(start_time, frequency, days_by_number)
    end

    create! do |success, failure|
      success.html { redirect_to customer_root_url }
      failure.html { redirect_to customer_root_url }
    end
  end

  def pause
    @order     = Order.find(params[:id])
    start_date = Date.parse(params['start_date'])
    end_date   = Date.parse(params['end_date']) - 1.day

    redirect_to customer_root_url, warning: 'Dates can not be in the past' and return if start_date.past? || end_date.past?
    redirect_to customer_root_url, warning: 'Start date can not be past end date' and return if end_date <= start_date

    schedule = @order.schedule
    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }
    (start_date..end_date).each   { |date| schedule.add_exception_time(date.to_time) }

    @order.schedule = schedule

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
end
