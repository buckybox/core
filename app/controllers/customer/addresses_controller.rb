class Customer::AddressesController < Customer::ResourceController

  def update
    @address = current_customer.address

    if @address.update_attributes(params[:address])
      flash.now[:notice] = "Address updated successfully"
    end
  end

  protected

  def resource
    current_customer.address
  end
end
