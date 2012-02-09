class Customer::OrdersController < Customer::BaseController
  actions :update

  belongs_to :customer

  respond_to :html, :xml, :json

  def update
    update! { customer_root_path }
  end

  def pause
    @order = Order.find(params[:id])
    @customer = Customer.find(params[:customer_id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        format.html { redirect_to customer_root_path, notice: 'Pause successfully applied.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, error: 'There was a problem pausing your order.' }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  protected

  def collection
    @orders ||= end_of_association_chain.active
  end
end
