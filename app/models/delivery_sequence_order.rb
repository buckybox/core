class DeliverySequenceOrder < ActiveRecord::Base
  attr_accessible :address_hash, :day, :position, :route_id

  belongs_to :route

  after_save :update_dso # cache results on delivery model
  default_value_for :position, -1

  private

  # DSO stands for DeliverySequenceOrder
  def update_dso
    Delivery.matching_dso(self).each do |delivery|
      next if delivery.dso == position
      next if delivery.archived?
      delivery.dso = position
      delivery.save!
    end
  end

  def address=(address)
    address_hash = address.address_hash
  end

  def self.for_delivery(delivery)
    attrs = {route_id: delivery.route_id, address_hash: delivery.address.address_hash, day: delivery.delivery_list.date.wday}
    dso = DeliverySequenceOrder.where(attrs).first
    dso ||= DeliverySequenceOrder.create(attrs)
    dso
  end
end
