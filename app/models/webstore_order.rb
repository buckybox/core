# NOTE: Not sure yet if this should be a DB model, for now making it so. Might be useful to track unfinished orders.

class WebstoreOrder < ActiveRecord::Base
  belongs_to :account
  belongs_to :box
  belongs_to :route

  has_one :distributor, through: :account

  serialize :exclusions, Array
  serialize :substitutes, Array
  serialize :extras, Hash

  attr_accessible :box, :remote_ip

  def self.start_order(distributor, box_id, options = {})
    box = distributor.boxes.find(box_id)
    WebstoreOrder.create(box: box, remote_ip: options[:remote_ip])
  end

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
  end

  def order_price
  end

  def completed?
  end
end
