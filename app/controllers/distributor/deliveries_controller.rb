class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions :collection => [:update_status, :master_packing_sheet]
  belongs_to :distributor

  respond_to :html, :xml, :except => :update_status
  respond_to :json, :except => :master_packing_sheet

  def index
    unless params[:date] && params[:view]
      redirect_to date_distributor_deliveries_path(current_distributor, Date.today, 'packing') and return
    end

    index! do
      @selected_date = Date.parse(params[:date])
      @route_id = params[:view].to_i

      start_date = Date.today - 1.week
      end_date   = Date.today + 4.weeks

      @routes = current_distributor.routes

      @delivery_lists = DeliveryList.collect_lists(current_distributor, start_date, end_date)
      @delivery_list  = @delivery_lists.find { |delivery_list| delivery_list.date == @selected_date }
      @all_deliveries = @delivery_list.deliveries

      @packing_lists = PackingList.collect_lists(current_distributor, start_date, end_date)
      @packing_list  = @packing_lists.find  { |packing_list| packing_list.date == @selected_date }
      @all_packages  = @packing_list.packages

      if @route_id != 0
        @items = @all_deliveries.select{ |delivery| delivery.route.id == @route_id }
        @route = @routes.find(@route_id)
      else
        @items = @all_packages
        @route = @routes.first
      end
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

  def reposition
    date = Date.parse(params[:date])
    delivery_order = params[:delivery]

    @delivery_list = current_distributor.delivery_lists.find_by_date(Date.parse(params[:date]))

    puts '-'*80
    puts date
    puts delivery_order.inspect
    puts @delivery_list.deliveries.map(&:id).inspect

    all_saved = true

    delivery_order.each_with_index do |delivery_id, index|
      delivery = current_distributor.deliveries.find(delivery_id)
      delivery.position = index + 1
      all_saved &= delivery.save
    end

    if all_saved
      head :ok
    else
      head :bad_request
    end
  end
end
