module Admin::DistributorsHelper
  ERROR_CLASS = 'error'
  PASS_CLASS = ''

  def delivery_route_status(route)
    route.blank? ? ERROR_CLASS : PASS_CLASS
  end

  def order_status(route, box)
    delivery_days = box.delivery_days.split(',').map{ |d| d.strip.downcase.to_sym }
    delivery_days = Route.delivery_day_numbers(delivery_days)

    frequency = box.delivery_frequency

    next_delivery_date = Time.zone.parse(box.next_delivery_date)

    schedule = Bucky::Schedule.build(next_delivery_date, frequency, delivery_days)

    return (route.blank? || !route.schedule.include?(schedule) ? ERROR_CLASS : PASS_CLASS)
  end

  def box_type_status(distributor, box)
    distributor.boxes.find_by_name(box.box_type).blank? ? ERROR_CLASS : PASS_CLASS
  end
end
