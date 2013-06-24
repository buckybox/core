module Distributor::DeliveriesHelper
  CALENDAR_DATE_SIZE = 60

  def calendar_nav_length(dates, months)
    nav_length = dates.size + months.size

    return "width:#{nav_length * CALENDAR_DATE_SIZE}px;"
  end

  def date_class(date)
    'today' if date.today?
  end

  def count_selected(start_date, date_list, date)
    date = Date.parse(date) unless date.is_a?(Date)

    scroll_date = date - 1.week
    scroll_date = start_date if scroll_date < start_date

    if date == date_list
      element_id = 'selected'
    elsif scroll_date == date_list
      element_id = 'scroll-to'
    end

    return element_id
  end

  def count_class(current_distributor, date)
    delivery_list = current_distributor.delivery_lists.where(date: date).first
    if delivery_list.blank?
      'out_of_range'
    elsif !delivery_list.all_finished?
      'has_pending'
    end
  end

  def count_title(current_distributor, date)
    delivery_list = current_distributor.delivery_lists.where(date: date).first
    if delivery_list.blank?
      'open for new orders'
    elsif !delivery_list.all_finished?
      'pending deliveries'
    end
  end

  def reschedule_dates(route)
    dates = route.schedule.next_occurrences(5, Time.current)
    options_from_collection_for_select(dates, 'to_date', 'to_date')
  end

  def order_delivery_route_name(order, date)
    delivery = order.delivery_for_date(date)
    delivery.route.name if delivery
  end

  def order_delivery_count(calendar_array, date, route = nil)
    data = calendar_array.select{|cdate, cdata| cdate == date}[0][1]

    if route
      Order.find(data[:order_ids]).select{|o| o.route(date) == route}.size
    else
      data[:order_ids].size
    end
  end

  def icon_display(status, icon_status)
    'display:none;' unless status == icon_status
  end

  def contents_description(item, date = nil)
    if item.is_a?(Order)
      Package.contents_description(item.box, item.predicted_order_extras(date))
    else
      item = item.package if item.is_a?(Delivery)
      item.contents_description
    end
  end

  def delivery_quantity(distributor, date, route_id = nil)
    delivery_list = current_distributor.delivery_lists.where(date: date).first
    if delivery_list
      delivery_list.quantity_for(route_id)
    else
      Order.order_count(distributor, date, route_id)
    end
  end

  def dso_tooltip(number)
    tooltip_text = "Delivery Sequence Number<br/>(printed on labels)"
    link_to number, '#', rel: 'tooltip', class: 'dso-tooltip', data: { placement: 'bottom', 'original-title' => tooltip_text, 'html' => true }
  end

  #TODO: Move the following address methods into a mapping module that is included in orders, deliveries, and packages (or something like that)
  def item_address(item)
    if item.is_a?(Order)
      item.account.customer.address.join
    else
      item = item.package if item.is_a?(Delivery)
      item.archived_address
    end
  end

  def item_address_text(item)
    if item.is_a?(Order)
      item.account.customer.address.address_1
    else
      item = item.package if item.is_a?(Delivery)
      item.archived_address.split(', ').first
    end
  end

  def display_address(item)
    link_to_google_maps(item_address(item), link_text: item_address_text(item), link_class: 'delivery-address')
  end

  def map_pin(item)
    pin = %q(<i class='icon-map-marker'></i>)
    link_to_google_maps(item_address(item), link_text: pin, link_class: 'map-pin')
  end

  def link_to_google_maps(address, options = {})
    link_text = options[:link_text] || ''
    trailing_text = options[:trailing_text].to_s

    link_to(link_text.html_safe, map_link(address), target: '_blank', class: options[:link_class]) + trailing_text
  end

  def map_link(address)
    address = address + ", #{[current_distributor.city, current_distributor.country.full_name].reject(&:blank?).join(", ")}"
    "http://maps.google.com/maps?q=#{Rack::Utils.escape(address)}"
  end
end
