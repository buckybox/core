class CopyDeliveryPositionToDso < ActiveRecord::Migration
  def up
    Delivery.find_each do |delivery|
      dso = DeliverySequenceOrder.for_delivery(delivery)
      if dso.position == -1
        dso.position = delivery.position
        dso.save!
      end
    end
  end

  def down
  end
end
