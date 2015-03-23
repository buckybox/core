object @delivery_service

attributes :id, :name, :instructions, :name_days_and_fee, :pickup_point
attributes :sun, :mon, :tue, :wed, :thu, :fri, :sat

node(:fee) { |delivery_service| delivery_service.fee.to_s }
node(:start_dates) { |delivery_service| Order.start_dates(delivery_service) }
node(:dates_grid) { Order.dates_grid }

