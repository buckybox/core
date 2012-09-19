class Webstore
  attr_reader :distributor, :customer, :order, :ip_address, :next_step

  def initialize(distributor, session, customer, ip_address)
    webstore_session = session[:webstore]

    if webstore_session
      @order     = WebstoreOrder.find(webstore_session[:webstore_order_id])
      @next_step = webstore_session[:next_step]
    end

    @distributor = distributor
    @customer    = customer
    @ip_address  = ip_address
  end

  def to_session
    { webstore_order_id: @order.id, next_step: next_step }
  end

  def process_params(webstore_params)
    start_order(webstore_params[:box_id])              if webstore_params[:box_id]
    customise_order(webstore_params[:customise])       if webstore_params[:customise]
    login_customer(webstore_params[:user])             if webstore_params[:user]
    update_delivery_information(webstore_params)       if webstore_params[:route]
    add_address_information(webstore_params[:address]) if webstore_params[:address]

    @order.save
  end

  private

  STORE     = :store
  CUSTOMISE = :customise
  LOGIN     = :login
  DELIVERY  = :delivery
  COMPLETE  = :complete
  PLACED    = :placed

  def add_address_information(address_information)
    customer = @order.customer
    customer.first_name = address_information[:name]

    address = customer.address
    address.address_1 = address_information[:street_address]
    address.address_2 = address_information[:street_address_2]
    address.suburb    = address_information[:suburb]
    address.city      = address_information[:city]
    address.postcode  = address_information[:post_code]

    customer.save
    @next_step = PLACED
  end

  def update_delivery_information(delivery_information)
    assign_route(delivery_information[:route])             if delivery_information[:route]
    set_schedule(delivery_information[:schedule])          if delivery_information[:schedule]
    assign_extras_frequency(delivery_information[:extras]) if delivery_information[:extras]

    @next_step = COMPLETE
  end

  def login_customer(user_information)
    email = user_information[:email]
    customer = Customer.find_by_email(email)

    unless customer
      route = Route.default_route(distributor)
      first_name = 'Webstore Temp'
      Customer.create(distributor: distributor, email: email, route: route, first_name: first_name)
    end

    @order.account = customer.account

    @next_step = DELIVERY
  end

  def customise_order(customise)
    add_exclusions_to_order(customise[:dislikes]) if customise[:dislikes]
    add_substitutes_to_order(customise[:likes])   if customise[:likes]
    add_extras_to_order(customise[:extras])       if customise[:extras]

    @next_step = LOGIN
  end

  def start_order(box_id)
    box = Box.where(id: box_id, distributor_id: @distributor.id).first
    @order = WebstoreOrder.create(box: box, remote_ip: @ip_address)
    @order.account = @customer.account if @customer

    @next_step = (box.customisable? ? CUSTOMISE : LOGIN)
  end

  def assign_extras_frequency(extra_information)
    extra_frequency = extra_information[:extra_frequency]
    @order.extras_one_off = (extra_frequency == 'true' ? true : false)
  end

  def set_schedule(schedule_information)
    frequency = schedule_information[:frequency]
    start_time = Time.zone.parse(schedule_information[:start_date])

    @order.frequency = frequency

    if frequency == 'single'
      @order.create_schedule_for(:schedule, start_time, frequency)
    else
      days_by_number = schedule_information[:days].map { |d| d.first.to_i }
      @order.create_schedule_for(:schedule, start_time, frequency, days_by_number)
    end
  end

  def assign_route(route_information)
    route_id       = route_information[:route]
    customer       = @order.customer
    customer.route = Route.find(route_id)
    customer.save
  end

  def add_extras_to_order(extras)
    extras.delete('add_extra')
    @webstore_order.extras = extras.select { |k,v| v.to_i > 0 }
  end

  def add_substitutes_to_order(substitutes)
    substitutes.delete('')
    @order.substitutes = substitutes
  end

  def add_exclusions_to_order(exclusions)
    exclusions.delete('')
    @order.exclusions = exclusions
  end
end
