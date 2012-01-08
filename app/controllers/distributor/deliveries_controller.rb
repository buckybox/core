class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions :collection => :update_status
  belongs_to :distributor

  respond_to :html, :xml, :except => :update_status
  respond_to :json

  def index
    index! do
      start_date = Time.now - 1.week
      end_date = start_date + 15.weeks
      @selected_date = Date.parse(params['date']) if params['date']

      @calendar_hash = {}

      current_distributor.orders.each do |order|
        order.schedule.occurrences_between(start_date, end_date).each do |occurrence|
          occurrence = occurrence.to_date

          @calendar_hash[occurrence] = { count: 0, order_ids: [] } if @calendar_hash[occurrence].nil?
          @calendar_hash[occurrence][:count] += 1
          @calendar_hash[occurrence][:order_ids] << order.id
        end
      end

      @orders = ( @selected_date ? Order.find(@calendar_hash[@selected_date][:order_ids]) : [] )

      @calendar_hash = @calendar_hash.to_a.sort!
      number_of_month_dividers = @calendar_hash.map{ |ch| ch.first.strftime("%m %Y") }.uniq.length - 1

      @nav_length = @calendar_hash.length + number_of_month_dividers

      @route = Route.best_route(current_distributor)
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.where(id: params[:deliveries])
    status = params[:status]

    if status == 'reschedule' || status == 'pack'
      missed_type = status
      date = Date.parse(params[:date])
      status = 'cancelled'
    end

    valid_status = Delivery::STATUS.include?(status)

    if valid_status && deliveries.map{ |d| d.update_attribute('status', status) }.all?
      head :ok
    else
      head :bad_request
    end
  end
end
