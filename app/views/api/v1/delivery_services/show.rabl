object @delivery_service

cache [:delivery_service, root_object.cache_key]

attributes :id, :name, :instructions, :name_days_and_fee, :pickup_point, :start_dates
attributes :sun, :mon, :tue, :wed, :thu, :fri, :sat

node(:fee) { |delivery_service| delivery_service.fee.to_s }
node(:dates_grid) { Order.dates_grid }
node(:cache_key) { |delivery_service| Digest::SHA256.hexdigest(delivery_service.cache_key) }

