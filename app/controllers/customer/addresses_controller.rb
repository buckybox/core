class Customer::AddressesController < Customer::ResourceController

  def update
    @address = current_customer.address

    if @address.update_attributes(params[:address])
      if current_customer.has_yellow_deliveries?
        flash.now[:alert] = "WARNING: Your delivery address has been updated, but you have an impending delivery that is too late to change. Your address change will take effect on #{current_customer.distributor.beginning_of_green_zone.to_s(:day_date_month)}."
      else
        flash.now[:notice] = "Your delivery address has been updated, this will take effect on your next delivery."
      end
    end
  end

  protected

  def resource
    current_customer.address
  end
end
