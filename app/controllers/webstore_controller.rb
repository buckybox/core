class WebstoreController < ApplicationController
  before_filter :get_distributor
  before_filter :get_box, except: :store

  def store
    @hide_sidebars = true
    @boxes = @distributor.boxes
  end

  def buy
    box_id = params[:box_id]

    add_to_cart(box_id: box_id, force_clear: true)
  end

  def customer_details
    likes    = params[:buy][:likes]
    dislikes = params[:buy][:dislikes]
    extras   = params[:extra]

    add_to_cart(likes: likes, dislikes: dislikes, extras: extras)
  end

  def payment
    address = params[:address]

    add_to_cart(address: address) unless address.blank?
  end

  def success
    #create_customer
    #create_order
  end

  def create_password
    # save password
  end

  private

  def add_to_cart(args)
    session[:cart] = { order: {} } if args.delete(:force_clear) || session[:cart].blank?
    session[:cart][:order].merge!(args)
  end

  def get_box
    if params[:box_id]
      @box = Box.find(params[:box_id])
    else
      @box = Box.find(session[:cart][:order][:box_id])
    end
  end

  def get_distributor
    @distributor = Distributor.find_by_parameter_name(params[:distributor_parameter_name])
  end
end
