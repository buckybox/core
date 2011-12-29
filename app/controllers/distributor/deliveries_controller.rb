class Distributor::DeliveriesController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def index
    index! do
      start_date = Time.now - 1.week
      end_date = start_date + 25.weeks

      @calendar_hash = {}

      current_distributor.orders.active.each do |order|
        order.schedule.occurrences_between(start_date, end_date).each do |occurrence|
          occurrence = occurrence.to_date

          @calendar_hash[occurrence] = 0 if @calendar_hash[occurrence].nil?
          @calendar_hash[occurrence] += 1
        end
      end

      number_of_months = @calendar_hash.map{|ch| ch.first.strftime("%m %Y")}.uniq.length

      @nav_length = @calendar_hash.length + number_of_months
    end
  end
end
