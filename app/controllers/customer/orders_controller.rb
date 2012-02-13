class Customer::OrdersController < Customer::BaseController
  actions :update

  belongs_to :customer

  respond_to :html, :xml, :json

  def update
    update! { customer_root_path }
  end

  def pause
    @customer  = Customer.find(params[:customer_id])
    @order     = Order.find(params[:id])

    start_date = Date.parse(params['start_date'])
    end_date   = Date.parse(params['end_date']) - 1.day

    schedule   = @order.schedule

    redirect_to customer_root_path, warning: 'Dates can not be in the past' and return if start_date.past? || end_date.past?
    redirect_to customer_root_path, warning: 'Start date can not be past end date' and return if end_date <= start_date

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }
    (start_date..end_date).each   { |date| schedule.add_exception_time(date.to_time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to customer_root_path, notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, error: 'There was a problem pausing your order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  def remove_pause
    @customer  = Customer.find(params[:customer_id])
    @order     = Order.find(params[:id])

    schedule   = @order.schedule

    schedule.exception_times.each { |time| schedule.remove_exception_time(time) }

    @order.schedule = schedule

    respond_to do |format|
      if @order.save
        format.html { redirect_to customer_root_path, notice: 'Pause successfully removed.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, error: 'There was a problem removing the pause from your order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def collection
    @orders ||= end_of_association_chain.active
  end
end
