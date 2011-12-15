module Distributor::BoxesHelper
  def price_for(box)
    "$#{box.price}"
  end

  def option_status_for(option_value)
    status = option_value ? '&#x2714' : '&#10007'
    "<span class=\"status status-#{option_value}\">#{status}</span>".html_safe
  end
end
