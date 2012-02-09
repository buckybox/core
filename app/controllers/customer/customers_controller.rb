class Customer::CustomersController < Customer::BaseController
  actions :update

  respond_to :html, :xml, :json

  def update
    @customer = Customer.find(params[:id])
    redirect_to customer_root_url and return unless @customer == current_customer

    update! { customer_root_url }
  end

  def update_password
    @customer = Customer.find(params[:id])
    redirect_to customer_root_url and return unless @customer == current_customer

    respond_to do |format|
      if @customer.update_attributes(params[:customer])
        sign_in @customer, bypass: true

        format.html { redirect_to customer_root_path, notice: 'Password successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_path, error: 'There was a problem changing your password.' }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end
end
