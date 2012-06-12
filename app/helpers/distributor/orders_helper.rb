module Distributor::OrdersHelper
  def order_frequencies
    Order::FREQUENCIES.map{ |frequencies| [frequencies.titleize, frequencies] }
  end

  def order_start_dates(route)
    from_time = route.distributor.window_end_at.to_time_in_current_zone
    next_occurrences = route.schedule.next_occurrences(28, from_time)
    next_occurrences.map { |time| [time.strftime("%A, %B %d, %Y"), time.to_date] }
  end
end
