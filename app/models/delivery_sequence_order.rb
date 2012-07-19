class DeliverySequenceOrder < ActiveRecord::Base
  attr_accessible :address_id, :day, :position, :route_id
end
