module Distributor::OrdersHelper
  def order_frequencies
    Order::FREQUENCIES.map{ |frequencies| [frequencies.titleize, frequencies] }
  end

  def order_start_dates(route)
    route.schedule.next_occurrences(7, Time.now).map { |time| [time.strftime("%A, %B %d, %Y"), time.to_date] }
  end
end
