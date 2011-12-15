module Distributor::BoxesHelper
  def price_for(box)
    "$#{box.price}"
  end

  def option_status_for(option_value)
    status = option_value ? '&#x2714' : '&#10007'
    content_tag :span, status, :class => "status status-#{option-value}"
  end
end
