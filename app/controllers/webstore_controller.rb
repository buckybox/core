class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_webstore_order, except: [:store]

  def store
    session[:webstore] = nil
    @boxes = @distributor.boxes.not_hidden
  end

  def process_step
    webstore = Webstore.new(@distributor, session, request.remote_ip)
    webstore.process_params(params)

    session[:webstore] = webstore.to_session

    redirect_to action: webstore.next_step, distributor_parameter_name: @distributor.parameter_name
  end

  def customise
    @stock_list = @distributor.line_items
    @box = @webstore_order.box
    @extras = @box.extras.alphabetically
  end

  def login
    @registered_options = [
      ["I'm a new customer", 'new'],
      ["I'm a returning customer", 'returning']
    ]
    @checked = @registered_options.first.last
  end

  def delivery
    @routes = @distributor.routes.map { |route| [route.name_days_and_fee, route.id] }
  end

  def complete
  end

  private

  def get_webstore_order
    @webstore_order = WebstoreOrder.find(session[:webstore_order_id]) if session[:webstore_order_id]
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
