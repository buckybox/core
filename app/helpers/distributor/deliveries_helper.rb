module Distributor::DeliveriesHelper
  def calendar_nav_length(calendar_hash)
    number_of_month_dividers = calendar_hash.map{ |ch| ch.first.strftime("%m %Y") }.uniq.length - 1
    nav_length = calendar_hash.length + number_of_month_dividers

    return "#{nav_length * 59}px"
  end

  def reschedule_dates(route)
    dates = route.schedule.next_occurrences(5, Time.now)
    options_from_collection_for_select(dates, 'to_date', 'to_date')
  end

  def delivery_icons(status, delivery = nil)
    case status
    when 'pending'
      status_icon = 'icon-status-pending.png'
      options = { title:'PENDING delivery' }
    when 'delivered'
      status_icon = 'icon-status-done.png'
      options = { title:'Delivery has been COMPLETED' }
    when 'cancelled'
      status_icon = 'icon-status-oops.png'
      options = { title:'MISSED DELIVERY, customer has not been charged' }
    when 'rescheduled'
      status_icon = 'icon-status-refresh.png'
      options = {
        title:"Missed delivery, REDELIVER on #{delivery.new_delivery.date.strftime("%A %d %B")} (#{delivery.route.name})"
      }
    when 'repacked'
      status_icon = 'icon-status-repack.png'
      options = {
        title:"Missed delivery, NEW BOX scheduled for #{delivery.new_delivery.date.strftime("%A %d %B")}"
      }
    end

    image_tag status_icon, { :alt => status }.merge(options)
  end

  def order_delivery_route_name(order, date)
    delivery = order.delivery_for_date(date)
    delivery.route.name if delivery
  end

  def order_delivery_count(calendar_array, date, route = nil)
    data = calendar_array.select{|cdate, cdata| cdate == date}[0][1]

    if route
      orders = Order.find(data[:order_ids]).select{|o| o.route(date) == route}.size
    else
      data[:order_ids].size
    end
  end
end
