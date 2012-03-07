class Customer::CustomersController < Customer::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    update! { customer_root_url }
  end

  def update_password
    respond_to do |format|
      if current_customer.update_attributes(params[:customer])
        sign_in current_customer, bypass: true

        format.html { redirect_to customer_root_url, notice: 'Password successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to customer_root_url, error: 'There was a problem changing your password.' }
        format.json { render json: current_customer.errors, status: :unprocessable_entity }
      end
    end
  end
end
