class Customer::CustomersController < Customer::ResourceController
  actions :update

  respond_to :html, :xml, :json

  def update
    current_customer.address.skip_validations(:address) do
      if current_customer.update_attributes(params[:customer])
        redirect_to customer_root_url, notice: 'Your details have successfully been updated.'
      else
        redirect_to customer_root_url, flash: { error: current_customer.errors.full_messages.join('<br>').html_safe }
      end
    end
  end

  def update_password
    current_customer.address.skip_validations(:address, :phone) do
      if current_customer.update_attributes(params[:customer])
        sign_in current_customer, bypass: true

        redirect_to customer_root_url, notice: 'Password successfully updated.'
      else
        redirect_to customer_root_url, flash: {error: "There was a problem changing your password. #{current_customer.errors.full_messages.join(', ')}"}
      end
    end
  end

protected

  def resource
    current_customer
  end

  def begin_of_association_chain
    nil
  end
end
