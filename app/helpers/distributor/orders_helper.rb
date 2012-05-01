module Distributor::OrdersHelper
  def order_frequencies
    Order::FREQUENCIES.map{ |frequencies| [frequencies.titleize, frequencies] }
  end

  def order_start_dates(route)
    next_occurrences = route.schedule.next_occurrences(28, route.distributor.window_end_at.to_time_in_current_zone)
    next_occurrences.map { |time| [time.strftime("%A, %B %d, %Y"), time.to_date] }
  end
end
