object @box

attributes :id, :name, :description, :extras_limit
attribute :exclusions_limit => :exclusions_limit
attribute :dislikes? => :dislikes
attribute :substitutions_limit => :substitutions_limit
attribute :likes? => :likes
attribute :customisable? => :customizable
attribute :extras_allowed? => :extras_allowed
attribute :extras_unlimited? => :extras_unlimited
attribute :exclusions_unlimited? => :exclusions_unlimited
attribute :substitutions_unlimited? => :substitutions_unlimited

node(:price) { |box| box.price.to_s }

unless @embed['extras'].nil?
  node :extras do |box|
    if box.available_extras.empty?
      [] # NOTE: ugly hack to return an "extras" array even if empty
    else
      child box.available_extras, object_root: false do
        attributes :id, :name, :unit
        node(:price) { |extra| extra.price.to_s }
        node(:with_price_per_unit) { |extra| extra.decorate.with_price_per_unit }
        node(:with_unit) { |extra| extra.decorate.with_unit }
        node(:formatted_price) { |extra| extra.decorate.formatted_price }
      end
    end
  end
end

unless @embed['images'].nil?
  node :images do |box|
    @images[box.id]
  end
end

unless @embed['box_items'].nil?
  node :box_items do
    @distributor.line_items.select('id, name')
  end
end

