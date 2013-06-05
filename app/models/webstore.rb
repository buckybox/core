# NOTE: this model is tightly coupled to the controller and full of spaghetti code

class Webstore
  attr_reader :controller, :distributor, :order

  def initialize(controller, distributor)
    @controller  = controller # FIXME: models should not talk to controllers
    @distributor = distributor

    @order = WebstoreOrder.find_by_id(webstore_session[:webstore_order_id]) if webstore_session
  end

  def process_params
    webstore_params = @controller.params[:webstore_order]
    return process_webstore(webstore_params) if webstore_params.present?

    payment_params = @controller.params[:webstore_payment]
    return process_payment(payment_params) if payment_params.present?
  end

  def process_webstore(webstore_params)
    start_order(webstore_params[:box_id])        if webstore_params[:box_id]
    customise_order(webstore_params)             if webstore_params[:customise] || webstore_params[:extras]
    login_customer(webstore_params[:user])       if webstore_params[:user]
    update_delivery_information(webstore_params) if webstore_params[:route]
    add_address_and_payment_select(webstore_params)    if webstore_params[:complete]

    @order.save
  end

  def process_payment(payment_params)
    if (credit_card_params = payment_params[:credit_card])
      process_credit_card(CreditCard.new(credit_card_params)) if credit_card_params.present?
    end
    if @order.no_payment_action? && @order.create_order
      customer = @controller.current_customer
      CustomerCheckout.track(customer) unless @controller.current_admin.present?
      @order.placed_step
      @controller.flash[:notice] = 'Your order has been placed'
    else
      @controller.flash[:error] = 'There was a problem completing your order'
      @order.payment_step
    end
    return true
  end

  def next_step
    @order.status
  end

  def to_session
    { webstore_order_id: @order.id }
  end

  def webstore_session=(session_hash)
    @controller.session[:webstore] = session_hash
  end

  def webstore_session
    @controller.session[:webstore]
  end

  def current_email=(email)
    webstore_session[:email] = email
  end

  def current_email
    webstore_session[:email] if webstore_session
  end

private

  def payment_due?(order)
    return false if order.account.blank? 

    (order.account.balance - order.order_price) < 0
  end

  def start_order(box_id)
    box = Box.where(id: box_id, distributor_id: @distributor.id).first
    customer = @controller.current_customer

    @order = WebstoreOrder.create(box: box, distributor: @distributor, remote_ip: @controller.request.remote_ip)
    @order.account = customer.account if customer

    if box.customisable?
      @order.customise_step
    else
      if @controller.customer_signed_in?
        @order.delivery_step
      else
        @order.login_step
      end
    end

    self.webstore_session = to_session
  end

  def customise_order(customise)
    customise_params = customise[:customise]
    add_exclusions_to_order(customise_params[:dislikes_input]) if customise_params
    add_substitutes_to_order(customise_params[:likes_input])   if customise_params

    extra_params = customise[:extras]
    add_extras_to_order(extra_params) if customise[:extras]

    if !@order.valid?
      @controller.customise_error
    elsif @controller.customer_signed_in? && @controller.current_customer.distributor == @distributor
        @order.delivery_step
    else
      @order.login_step
    end
  end

  def login_customer(user_information)
    email    = user_information[:email]
    password = user_information[:password]
    customer = Customer.find_by_email(email)
    customer_new = user_information[:registered] != 'returning'

    if email.blank?
      @controller.flash[:error] = 'You must provide an email address.'
      @order.login_step
    elsif !email_valid?(email)
      @controller.flash[:error] = 'You must provide a valid email address.'
      @order.login_step
    elsif customer.nil? && customer_new
      self.current_email = email
      @order.delivery_step
    elsif customer.present? && customer.valid_password?(password) && customer.distributor == @distributor
      CustomerLogin.track(customer) unless @controller.current_admin.present?
      @controller.sign_in(customer)
      @order.delivery_step
    else
      new_registration = (user_information[:registered] == 'new')

      if new_registration && !customer.nil?
        error_description = "This account already exists. <span><i style=\"padding-right: 4px\" class=\"icon-lock\"></i><a href=\"#{@controller.new_customer_password_path(distributor: @distributor.parameter_name)}\">Did you lose your password?</a></span>".html_safe
      else
        error_description = "You have not provided the correct email address or password for this store. Please try again. <span><i style=\"padding-right: 4px\" class=\"icon-lock\"></i><a href=\"#{@controller.new_customer_password_path(distributor: @distributor.parameter_name)}\">Lost your password?</a></span>".html_safe

      end

      @controller.flash[:error] = error_description
      @order.login_step
    end
  end

  def email_valid?(email)
    email.is_a?(String) && !email.match(Devise.email_regexp).nil?
  end

  def update_delivery_information(delivery_information)
    assign_route(delivery_information[:route])                      if delivery_information[:route]
    set_schedule(delivery_information[:schedule_rule])              if delivery_information[:schedule_rule]
    assign_extras_frequency(delivery_information[:extra_frequency]) if delivery_information[:extra_frequency]

    if @controller.flash[:error].blank?
      @order.complete_step
    else
      @order.delivery_step
    end
  end

  def add_address_and_payment_select(webstore_params)
    address_information = webstore_params[:address]

    if address_information && address_information.keys == ["phone_type"]
      address_information = nil
    end

    payment_option = PaymentOption.new(webstore_params[:payment_method], @distributor)
    @controller.session[:webstore][:payment_method] = webstore_params[:payment_method]

    errors = false

    if address_information
      @controller.session[:webstore][:address] ||= {}
      %w(name street_address street_address_2 suburb city postcode phone_number phone_type).each do |input|
        @controller.session[:webstore][:address][input] = address_information[input]
      end

      errors = validate_address_information(address_information)
    end

    if errors
      @controller.flash[:error] = errors.join('<br>').html_safe
      @order.complete_step
    elsif !payment_due?(@order) && webstore_params[:payment_method] == 'paid'
      customer = find_or_create_customer(address_information)
      update_address(customer, address_information) if address_information
      @order.account = customer.account

      if @order.create_order
        CustomerCheckout.track(customer) unless @controller.current_admin.present?
        @order.placed_step
        @controller.flash[:notice] = 'Your order has been placed'
      else
        @controller.flash[:error] = 'There was a problem completing your order'
        @order.complete_step
      end
    elsif !payment_option.valid?
      @controller.flash[:error] = 'Please select a payment option'
      @order.complete_step
    else
      customer = find_or_create_customer(address_information)
      update_address(customer, address_information) if address_information

      payment_option = PaymentOption.new(webstore_params[:payment_method], @distributor)
      payment_option.apply(@order)

      @order.account = customer.account
      @order.payment_step
      @order.save!
    end
  end

  def process_credit_card(credit_card)
    if credit_card.authorize!(@order)
      if @order.create_order
        customer = @controller.current_customer
        CustomerCheckout.track(customer) unless @controller.current_admin.present?
        @order.placed_step
        @controller.flash[:notice] = 'Your order has been placed'
      elsif @order.order
        @controller.flash[:error] = 'You have already created this order'
      else
        @controller.flash[:error] = 'There was a problem completing your order'
        @order.payment_step
      end
    else
      @controller.flash[:error] = ['There was a problem with your credit card', credit_card.errors.full_messages.join(', ')].join(', ')
    end
  end

  def validate_address_information address_information
    errors = []
    errors << "Your name can't be blank" if address_information[:name].blank?

    attrs = {
      "street_address" => "address_1",
      "street_address_2" => "address_2",
      "suburb" => "suburb",
      "city" => "city",
      "postcode" => "postcode"
    }.inject({}) do |accu, (from, to)|
      accu.merge(to => address_information[from])
    end

    address = Address.new attrs
    address.distributor = @distributor
    address.phone = { type: address_information["phone_type"],
                      number: address_information["phone_number"] }

    return if address.skip_validations(:customer) { |address| address.valid? } && errors.empty?

    errors + address.errors.full_messages
  end

  def find_or_create_customer(address_information)
    return @controller.current_customer unless @controller.current_customer.nil?

    customer       = @order.distributor.customers.new(email: self.current_email)
    customer.route = @order.route
    customer.name  = address_information[:name]

    if customer.save
      Event.new_customer_webstore(customer)
      CustomerMailer.raise_errors do
        customer.send_login_details
      end
      
      CustomerLogin.track(customer) unless @controller.current_admin.present?
      @controller.sign_in(customer)
    end

    customer
  end

  def update_address(customer, address_information)
    customer.name              = address_information[:name]

    customer.address.phone     = {
      number: address_information[:phone_number],
      type:   address_information[:phone_type]
    }

    customer.address.address_1 = address_information[:street_address]
    customer.address.address_2 = address_information[:street_address_2]
    customer.address.suburb    = address_information[:suburb]
    customer.address.city      = address_information[:city]
    customer.address.postcode  = address_information[:postcode]

    customer.save
  end

  def add_exclusions_to_order(exclusions)
    unless exclusions.nil?
      exclusions.delete('')
      @order.exclusions = exclusions
    end
  end

  def add_substitutes_to_order(substitutions)
    unless substitutions.nil?
      substitutions.delete('')
      @order.substitutions = substitutions
    end
  end

  def add_extras_to_order(extras)
    unless extras.nil?
      extras.delete('add_extra')
      @order.extras = extras.select { |k,v| v.to_i > 0 }
    end
  end

  def assign_route(route_information)
    route_id     = route_information[:route]
    @order.update_customers_route(@controller.current_customer, route_id) unless @order.active_orders?
    @order.route = Route.find(route_id)
  end

  # @example schedule_information
  #   {"start_date"=>"2013-05-07", "frequency"=>"monthly", "days"=>{"2"=>"1", "16"=>"1", "23"=>"1"}}
  def set_schedule(schedule_information)
    frequency = schedule_information[:frequency]
    start = Date.parse(schedule_information[:start_date])

    if frequency == 'single'
      @order.schedule_rule = ScheduleRule.one_off(start)
    else
      if schedule_information[:days].nil?
        @controller.flash[:error] = 'The schedule requires you select a day of the week.'
      else
        days_of_the_month = schedule_information[:days].keys.map(&:to_i)
        week = days_of_the_month.first / ScheduleRule::DAYS.size

        days_of_the_week = days_of_the_month.map do |day|
          ScheduleRule::DAYS[day % ScheduleRule::DAYS.size]
        end

        @order.schedule_rule = ScheduleRule.recur_on(start, days_of_the_week, frequency.to_sym, week)
      end
    end
  end

  def assign_extras_frequency(extra_information)
    extra_frequency = extra_information[:extra_frequency]
    @order.extras_one_off = (extra_frequency == 'true' ? true : false)
  end
end
