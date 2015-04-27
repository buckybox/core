collection @delivery_services

cache @delivery_services.map { |delivery_service| delivery_service.cache_key }

extends 'api/v1/delivery_services/show'

