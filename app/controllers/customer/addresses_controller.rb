class Customer::AddressesController < Customer::ResourceController
  def update
    @address = resource

    current_customer.address.skip_validations(:phone) do
      update! do |success, failure|
        success.html do
          if current_customer.has_yellow_deliveries?
            flash[:alert] = "WARNING: Your delivery address has been updated, but you have an impending delivery that is too late to change. Your address change will take effect on #{current_customer.distributor.beginning_of_green_zone.to_s(:day_date_month)}."
          else
            flash[:notice] = "Your delivery address has been updated, this will take effect on your next delivery."
          end

          redirect_to customer_root_url
        end

        failure.html { redirect_to customer_root_url, flash: { error: resource.errors.full_messages.join('<br>').html_safe } }
      end
    end
  end

protected

  def resource
    current_customer.address
  end
end
