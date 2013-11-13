class Customer::CustomersController < Customer::BaseController

  def update_contact_details
    args = form_args(:customer_form_update_contact_details)
    form = Customer::Form::UpdateContactDetails.new(args)
    form.save ? successful_update('contact details') : failed_update(form)
  end

  def update_delivery_address
    args = form_args(:customer_form_update_delivery_address)
    form = Customer::Form::UpdateDeliveryAddress.new(args)
    form.save ? successful_update('delivery address', true) : failed_update(form)
  end

  def update_password
    args = form_args(:customer_form_update_password)
    form = Customer::Form::UpdatePassword.new(args)
    form.save ? successful_update('password') : failed_update(form)
  end

private

  def form_args(param_key)
    { customer: current_customer }.merge(params[param_key])
  end

  def successful_update(submitted_changes, next_delivery = false)
    notice = "Your #{submitted_changes} have been successfully updated."
    notice += " This will take effect on your next delivery." if next_delivery
    flash[:notice] = notice
    redirect_to customer_root_url
  end

  def failed_update(form)
    flash[:alert] = "Oops there was an issue: #{formatted_error_messages(form)}"
    redirect_to customer_root_url
  end

  def formatted_error_messages(form)
    form.errors.full_messages.join(", ").downcase
  end

end
