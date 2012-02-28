module Distributor::OrdersHelper
  def order_frequencies
    Order::FREQUENCIES.map{ |frequencies| [frequencies.titleize, frequencies] }
  end

  def order_start_dates(route)
    route.schedule.next_occurrences(7, Time.now).map { |time| [time.to_s(:day_month_date_year), time.to_date.to_s(:timestamp)] }
  end
end
