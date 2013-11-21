# app/views/api/v0/boxes/index.rabl
collection @boxes
attributes :id, :name, :description, :price_cents, :extras_limit
attribute :exclusions_limit => :exclusion_limit
attribute :substitutions_limit => :substitute_limit

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

unless @embed['box_items'].nil?
	node :box_items do
		@items.select('id, name')
	end  
end
