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
      @orders = []

      current_distributor.orders.active.each do |order|
        @orders << order if @selected_date && order.schedule.occurs_on?(@selected_date)

        order.schedule.occurrences_between(start_date, end_date).each do |occurrence|
          occurrence = occurrence.to_date

          @calendar_hash[occurrence] = 0 if @calendar_hash[occurrence].nil?
          @calendar_hash[occurrence] += 1
        end
      end

      @calendar_hash = @calendar_hash.to_a.sort!
      number_of_month_dividers = @calendar_hash.map{|ch| ch.first.strftime("%m %Y")}.uniq.length - 1

      @nav_length = @calendar_hash.length + number_of_month_dividers

      @route = Route.best_route(current_distributor)
    end
  end

  def update_status
    deliveries = current_distributor.deliveries.where(:id => params[:deliveries])
    status = params[:status] if Delivery::STATUS.include?(params[:status])

    if status && deliveries.map{ |d| d.update_attribute('status', status) }.all?
      head :ok
    else
      head :bad_request
    end
  end
end
