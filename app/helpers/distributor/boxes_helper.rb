module Distributor::BoxesHelper
  def option_status_for(option_value)
    status = option_value ? '&#x2714' : '&#10007'
    content_tag :span, status.html_safe, :class => "status status-#{option_value}"
  end
end
