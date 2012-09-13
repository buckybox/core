class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_webstore_order, except: [:store]

  def store
    session[:webstore_order_id] = nil
    @boxes = @distributor.boxes.not_hidden
  end

  def customise
    @stock_list = @distributor.line_items
    @box = @webstore_order.box
    @extras = @box.extras.alphabetically
  end

  def login
    
  end

  private

  def get_webstore_order
    if session[:webstore_order_id]
      @webstore_order = WebstoreOrder.find(session[:webstore_order_id])
    else
      @webstore_order = WebstoreOrder.start_order(@distributor, params[:box_id], remote_ip: request.remote_ip)
      session[:webstore_order_id] = @webstore_order.id
    end
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
