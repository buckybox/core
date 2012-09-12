# NOTE: Not sure yet if this should be a DB model, for now making it so. Might be useful to track unfinished orders.

class WebstoreOrder < ActiveRecord::Base
  belongs_to :distributor
  belongs_to :box
  belongs_to :order
  belongs_to :route
  belongs_to :account

  def thumb_url
    box.big_thumb_url
  end

  def box_name
    box.name
  end

  def box_price
    box.price
  end

  def box_description
    box.description
  end

  def route_name
    route.name
  end

  def route_fee
    route.fee
  end

  def order_extras_price
    order.extras_price
  end

  def order_price
    order.price
  end

  def completed?
    false
  end
end
