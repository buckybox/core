module Distributor::DeliveriesHelper
  def calendar_nav_length(calendar_hash)
    number_of_month_dividers = calendar_hash.map{ |ch| ch.first.strftime("%m %Y") }.uniq.length - 1
    nav_length = calendar_hash.length + number_of_month_dividers

    return "#{nav_length * 59}px"
  end
end
