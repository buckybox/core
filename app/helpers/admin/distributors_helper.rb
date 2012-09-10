module Admin::DistributorsHelper
  ERROR_CLASS = 'text-error'
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

  def extras_status(distributor, extras, box)
    box = distributor.find_box_from_import(box)
    if box.blank? || box.extras_unlimited? || box.extras_limit >= extras.collect(&:count).sum
      PASS_CLASS
    else
      ERROR_CLASS
    end
  end

  def extra_status(distributor, extra, box=nil)
    distributor.find_extra_from_import(extra, box).blank? ? ERROR_CLASS : PASS_CLASS
  end

  def show_extra(distributor, extra, box=nil)
    (found_extra = distributor.find_extra_from_import(extra, box)).present? ? "#{extra.count}x #{found_extra.name_with_price(0)}" : extra.to_s
  end
end
