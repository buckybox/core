class Customer::AddressesController < Customer::BaseController
  def update
    current_customer.address.skip_validations(:phone) do
      if current_customer.update_address(params[:address], notify_distributor: true)
        if current_customer.has_yellow_deliveries?
          flash[:alert] = "WARNING: Your delivery address has been updated, but you have an impending delivery that is too late to change. Your address change will take effect on #{current_customer.distributor.beginning_of_green_zone.to_s(:day_date_month)}."
        else
          flash[:notice] = "Your delivery address has been updated, this will take effect on your next delivery."
        end

        redirect_to customer_root_url
      else
        redirect_to customer_root_url, flash: { error: "You must fill in all the required fields." }
      end
    end
  end
end
