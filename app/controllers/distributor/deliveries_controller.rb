class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions :collection => :update_status
  belongs_to :distributor

  respond_to :html, :xml, :except => :update_status
  respond_to :json, :except => :master_packing_sheet

  #TODO: Pull out as much code as possible from here into a models and lib

  def index
    index! do
      start_date = Time.now - 1.week
      end_date = start_date + 6.weeks
      @selected_date = Date.parse(params[:date]) if params[:date]
      @calendar_hash = calendar_nav_data(start_date, end_date)

      unless params[:view] == 'packing'
        @route = (params[:view] ? current_distributor.routes.find(params[:view]) : Route.default_route(current_distributor))
      end

      if @calendar_hash[@selected_date]
        @orders = current_distributor.orders.find(@calendar_hash[@selected_date][:order_ids])

        if @route
          @orders.select! { |o| o.deliveries.map(&:route_id).include?(@route.id) }
        end

        @orders.sort!
      end

      @calendar_hash = @calendar_hash.to_a.sort
      @routes = current_distributor.routes

      if !@calendar_hash.blank? && @selected_date.nil?
        @selected_date = @calendar_hash.find { |sd| sd.first <= Date.today }

        if @selected_date
          @selected_date = @selected_date.first
        else
          @selected_date = @calendar_hash.first.first
        end

        redirect_to date_distributor_deliveries_url(current_distributor, @selected_date.to_s) and return
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

  private

  def calendar_nav_data(start_date, end_date)
    calendar_hash = {}

    current_distributor.orders.active.each do |order|
      order.schedule.occurrences_between(start_date, end_date).each do |occurrence|
        occurrence = occurrence.to_date

        calendar_hash[occurrence] = { count: 0, order_ids: [] } if calendar_hash[occurrence].nil?
        calendar_hash[occurrence][:count] += 1
        calendar_hash[occurrence][:order_ids] << order.id
      end
    end

    return calendar_hash
  end
end
