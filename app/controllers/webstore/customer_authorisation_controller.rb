class Webstore::CustomerAuthorisationController < Webstore::BaseController
  def customer_authorisation
    render 'customer_authorisation', locals: {
      order: current_order.decorate,
      customer_authorisation: Webstore::CustomerAuthorisation.new(cart: current_cart)
    }
  end

  def save_customer_authorisation
    args = { cart: current_cart }.merge(params[:webstore_customer_authorisation])
    customer_authorisation = Webstore::CustomerAuthorisation.new(args)
    customer_authorisation.save ? successful_customer_authorisation : failed_customer_authorisation(customer_authorisation)
  end

private

  def successful_customer_authorisation
    redirect_to webstore_delivery_options_path
  end

  def failed_customer_authorisation(customer_authorisation)
    flash[:alert] = 'We\'re sorry there was an error with your credentials.'
    render 'customer_authorisation', locals: {
      order: current_order.decorate,
      customer_authorisation: customer_authorisation,
    }
  end
end
