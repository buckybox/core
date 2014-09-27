object @delivery_service

attributes :id, :name, :fee, :instructions, :name_days_and_fee, :pickup_point
attributes :sun, :mon, :tue, :wed, :thu, :fri, :sat

node(:start_dates) { |delivery_service| Order.start_dates(delivery_service) }
node(:dates_grid) { Order.dates_grid }

