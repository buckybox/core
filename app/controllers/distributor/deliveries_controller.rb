class Distributor::DeliveriesController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def index
    index! do
      start_date = Time.now - 1.week
      end_date = start_date + 25.weeks
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

      number_of_month_dividers = @calendar_hash.map{|ch| ch.first.strftime("%m %Y")}.uniq.length - 1

      @nav_length = @calendar_hash.length + number_of_month_dividers

      @route = Route.best_route(current_distributor)
    end
  end
end
