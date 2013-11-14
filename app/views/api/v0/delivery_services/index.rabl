# app/views/api/v0/delivery_services/index.rabl
collection @delivery_services
attributes :id, :name, :fee_cents, :area_of_Service, :estimated_delivery_time