module RoutesHelper
  def route_delivery_dates(route)
    from_time = route.distributor.window_end_at.to_time_in_current_zone
    next_occurrences = route.occurrences_between(from_time, 12.weeks.from_now)
    next_occurrences.map { |time| [time.to_s(:day_month_date_year), time.to_date] }
  end
end
