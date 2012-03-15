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

    #TODO Notice messages on failure doesn't render to page, didn't really look 
    #into it as dialog box fields validate themselves (not perfect, but job for later)
    respond_to do |format|
      if @order.pause(start_date, end_date)
        format.html { redirect_to customer_root_path, notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, notice: 'There was a problem pausing your order.' }
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
