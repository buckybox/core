module Distributor::DeliveriesHelper
  CALENDAR_DATE_SIZE = 60

  def calendar_nav_length(dates, months)
    nav_length = dates.size + months.size

    "width:#{nav_length * CALENDAR_DATE_SIZE}px;"
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

    element_id
  end

  def date_class(distributor, date)
    if date > distributor.window_end_at
      return "out_of_range"
    else
      delivery_list = distributor.delivery_lists.find_by(date: date)
      return "has_pending" if delivery_list && !delivery_list.all_finished?
    end
  end

  def date_title(distributor, date)
    title = []

    if date > distributor.window_end_at
      title << "open for new orders"
    else
      delivery_list = distributor.delivery_lists.find_by(date: date)
      all_delivered = delivery_list && delivery_list.all_finished?

      title << (all_delivered ? "all delivered" : "pending deliveries")

      title << "closed for new orders" if date >= distributor.window_start_from
    end

    title.join(", ").freeze
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

  def delivery_quantity(distributor, date, delivery_service_id = nil)
    delivery_list = current_distributor.delivery_lists.where(date: date).first
    if delivery_list
      delivery_list.quantity_for(delivery_service_id)
    else
      Order.order_count(distributor, date, delivery_service_id)
    end
  end

  # TODO: Move the following address methods into a mapping module that is included in orders, deliveries, and packages (or something like that)
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
    pin = "<i class='icon-map-marker'></i>"
    link_to_google_maps(item_address(item), link_text: pin, link_class: 'map-pin')
  end

  def link_to_google_maps(address, options = {})
    link_text = options[:link_text] || ''
    trailing_text = options[:trailing_text].to_s

    link_to(link_text.html_safe, map_link(address), target: '_blank', class: options[:link_class]) + trailing_text
  end

  def map_link(address)
    address += ", #{[current_distributor.city, current_distributor.country.full_name].reject(&:blank?).join(', ')}"
    "http://maps.google.com/maps?q=#{Rack::Utils.escape(address)}"
  end
end
