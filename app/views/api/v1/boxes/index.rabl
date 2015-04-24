collection @boxes

cache @boxes.map { |box| box.cache_key(@embed) }

extends 'api/v1/boxes/show'
