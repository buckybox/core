class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions :collection => [:update_status, :master_packing_sheet]
  belongs_to :distributor

  respond_to :html, :xml, :except => :update_status
  respond_to :json, :except => :master_packing_sheet

  #TODO: Pull out as much code as possible from here into a models and lib

  def index
    index! do
      start_date = Date.today - 2.week
      end_date = start_date + 6.weeks

      # Must populate future times
      @delivery_lists = DeliveryList.collect_delivery_lists(
        current_distributor,
        start_date,
        end_date,
        future:true
      )

      @selected_date = Date.parse(params[:date]) if params[:date]
      @routes = current_distributor.routes

      if params[:view].nil?
        @route = @routes.first
      elsif params[:view].to_i != 0
        @route = @routes.find(params[:view])
      end

      #if @calendar_hash[@selected_date]
        #@orders = current_distributor.orders.find(@calendar_hash[@selected_date][:order_ids])
        #@orders.select! { |o| o.deliveries.map(&:route_id).include?(@route.id) } if @route
        #@orders.sort!
      #end

      #@calendar_hash = @calendar_hash.to_a.sort

      #if !@calendar_hash.blank? && @selected_date.nil?
        #@selected_date = @calendar_hash.find { |sd| sd.first <= Date.today }

        #if @selected_date
          #@selected_date = @selected_date.first
        #else
          #@selected_date = @calendar_hash.first.first
        #end

        #redirect_to date_distributor_deliveries_url(current_distributor, @selected_date.to_s) and return
      #end
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.where(id: params[:deliveries])
    status = params[:status]

    options = {}
    options[:date] = params[:date] if params[:date]

    if Delivery.change_statuses(deliveries, status, options)
      head :ok
    else
      head :bad_request
    end
  end

  def master_packing_sheet
    @selected_date = Date.parse(params[:date]) if params[:date]
    order_ids = params[:order].select{ |id, checked| checked.to_i == 1 }.keys
    @orders = current_distributor.orders.find(order_ids)

    render :layout => 'print'
  end
end
