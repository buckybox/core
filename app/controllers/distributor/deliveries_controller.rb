class Distributor::DeliveriesController < Distributor::BaseController
  custom_actions :collection => :update_status
  belongs_to :distributor

  respond_to :html, :xml, :except => :update_status
  respond_to :json

  #TODO: Pull out as much code as possible from here into a lib

  def index
    index! do
      start_date = Time.now - 1.week
      end_date = start_date + 15.weeks
      @selected_date = Date.parse(params['date']) if params['date']

      @calendar_hash = calendar_nav_data(start_date, end_date)
      @orders = ( @selected_date ? Order.find(@calendar_hash[@selected_date][:order_ids]) : [] )
      @calendar_hash = @calendar_hash.to_a.sort
      @routes = current_distributor.routes
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.where(id: params[:deliveries])
    status = params[:status]

    if status == 'reschedule' || status == 'pack'
      options = { missed_type: status, date: Date.parse(params[:date]) }
      status = 'cancelled'
    end

    if update_actions(deliveries, status, options)
      head :ok
    else
      head :bad_request
    end
  end

  private

  def calendar_nav_data(start_date, end_date)
    calendar_hash = {}

    current_distributor.orders.each do |order|
      order.schedule.occurrences_between(start_date, end_date).each do |occurrence|
        occurrence = occurrence.to_date

        calendar_hash[occurrence] = { count: 0, order_ids: [] } if calendar_hash[occurrence].nil?
        calendar_hash[occurrence][:count] += 1
        calendar_hash[occurrence][:order_ids] << order.id
      end
    end

    return calendar_hash
  end

  def update_actions(deliveries, status, options = {})
    return false if Delivery::STATUS.include?(status)

    if status == 'delivered'

    end

    valid_status && deliveries.map{ |d| d.update_attribute('status', status) }.all?
  end
end
