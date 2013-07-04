class WebstoreController < ApplicationController
  layout 'customer'

  before_filter :distributor_has_webstore?
  before_filter :setup_by_distributor
  before_filter :distributors_customer?, except: [:store, :start_checkout]

  def store
    store = Webstore::Store.new(distributor: current_distributor, logged_in_customer: logged_in_customer)
    @current_customer = store.customer
    products = store.products
    render 'store', locals: { webstore_products: Webstore::ProductDecorator.decorate_collection(products) }
  end

  def start_checkout
    checkout = Webstore::Checkout.new(distributor: current_distributor, logged_in_customer: logged_in_customer)
    @current_customer = checkout.customer
    distributors_customer?
    checkout.add_product!(params[:product_id]) ? successful_new_checkout(checkout) : failed_new_checkout
  end

  def customise_order
    render 'customise_order', locals: {
      order: current_order.decorate,
      customise_order: Webstore::CustomiseOrder.new(cart: current_cart)
    }
  end

  def save_order_customisation
    args = { cart: current_cart }.merge(params[:webstore_customise_order])
    customise_order = Webstore::CustomiseOrder.new(args)
    customise_order.save ? successful_order_customisation : failed_order_customisation(customise_order)
  end

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

  def delivery_options
    render 'delivery_options', locals: {
      order: current_order.decorate,
      delivery_options: Webstore::DeliveryOptions.new(cart: current_cart)
    }
  end

  def save_delivery_options
    args = { cart: current_cart }.merge(params[:webstore_delivery_options])
    delivery_options = Webstore::DeliveryOptions.new(args)
    delivery_options.save ? successful_delivery_options : failed_delivery_options(delivery_options)
  end

  def payment_options
    render 'payment_options', locals: {
      order: current_order.decorate,
      payment_options: Webstore::PaymentOptions.new(cart: current_cart)
    }
  end

  def save_payment_options
    args = { cart: current_cart }.merge(params[:webstore_payment_options])
    payment_options = Webstore::PaymentOptions.new(args)
    payment_options.save ? successful_payment_options : failed_payment_options(payment_options)
  end

  def completed
    render 'completed', locals: { 
      order: current_order.decorate,
      completed: Webstore::Completed.new(cart: current_cart)
    }
    # Temp reminder. Do this when it makes sense
    #CustomerLogin.track(@webstore_order.customer) unless current_admin.present?
  end

  def xplaced
    @order_price      = @webstore_order.order_price(current_customer)
    @current_balance  = (current_customer ? current_customer.account.balance : Money.new(0))
    @closing_balance  = @current_balance - @order_price
    @amount_due       = -@closing_balance
    @bank             = @distributor.bank_information
    @payment_required = @closing_balance.negative?
    @customer         = @webstore_order.customer
    @address          = @customer.address
    @schedule_rule    = @webstore_order.schedule_rule

    flash[:notice] = 'Your order has been placed'
  end

private

  def successful_payment_options
    redirect_to webstore_completed_path, notice: 'Your order has been placed.'
  end

  def failed_payment_options(payment_options)
    flash[:alert] = 'We\'re sorry there was an error saving your payment options.'
    render 'payment_options', locals: {
      order: current_order.decorate,
      delivery_options: payment_options,
    }
  end

  def successful_delivery_options
    redirect_to webstore_payment_options_path
  end

  def failed_delivery_options(delivery_options)
    flash[:alert] = 'We\'re sorry there was an error saving your delivery options.'
    render 'delivery_options', locals: {
      order: current_order.decorate,
      delivery_options: delivery_options,
    }
  end

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

  def successful_order_customisation
    redirect_to webstore_customer_authorisation_path
  end

  def failed_order_customisation(customise_order)
    flash[:alert] = 'We\'re sorry there was an error customising your order.'
    render 'customise_order', locals: {
      order: current_order.decorate,
      customise_order: customise_order,
    }
  end

  def successful_new_checkout(checkout)
    session[:cart_id] = checkout.cart_id
    redirect_to webstore_customise_order_path
  end

  def failed_new_checkout
    flash[:alert] = 'We\'re sorry there was an error starting your order.'
    redirect_to webstore_store_path
  end

  def current_cart
    @current_cart ||= Webstore::Cart.find(session[:cart_id])
  end

  def current_order
    @current_order ||= current_cart.order
  end

  alias_method :logged_in_customer, :current_customer
  def current_customer
    @current_customer ||= current_cart.customer
  end

  def distributors_customer?
    valid_customer = (current_customer.distributor == current_distributor)
    alert_message = 'This account is not for this webstore. Please logout first then try your purchase again.'
    redirect_to webstore_store_path, alert: alert_message and return unless valid_customer
  end

  def distributor_has_webstore?
    active_webstore = !current_distributor.nil? && current_distributor.active_webstore
    redirect_to Figaro.env.marketing_site_url and return unless active_webstore
  end

  def setup_by_distributor
    Time.zone = current_distributor.time_zone
    Money.default_currency = Money::Currency.new(current_distributor.currency)
  end

  def current_distributor
    @distributor ||= Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
