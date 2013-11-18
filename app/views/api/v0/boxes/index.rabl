# app/views/api/v0/boxes/index.rabl
collection @boxes
attributes :id, :name, :description, :price_cents

unless @embed['extras'].nil?
	child :extras do
	  attributes :id, :name, :unit, :price_cents
	end
end

unless @embed['images'].nil?
	node :images do |box|
		@box_images[box.id]
	end  
end

