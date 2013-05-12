class DeliverySort
  attr_accessor :items, :type

  def self.grouped_by_boxes(items)
    delivery_sort = new(items)
    delivery_sort.grouped_by_boxes
  end

  #FIXME: Checking by class is a code smell this can be done better but it is the current standard in this class so using if for now.
  def self.by_dso(items, distributor, date)
    if items.all? { |i| i.is_a?(Delivery) }
      by_real_dso(items)
    elsif items.all?{ |i| i.is_a?(Order) }
      by_predicted_dso(items, distributor, date)
    else
      raise 'Was expecting all Deliveries or all Orders.'
    end
  end

  def self.by_real_dso(deliveries)
    delivery_sort = new(deliveries)
    deliveries_in_hash = delivery_sort.grouped_by_addresses
    deliveries_in_hash.map(&:second).flatten
  end

  def self.by_predicted_dso(orders, distributor, date)
    list = DeliveryList.collect_list(distributor, date, order_ids: orders)
    list.deliveries
  end

  def initialize(items)
    if items.all?{|i| i.is_a? Package}
      self.type = Type.packages
    elsif items.all?{|i| i.is_a? Delivery}
      self.type = Type.deliveries
    elsif items.all?{|i| i.is_a? Order}
      self.type = Type.orders
    else
      raise 'Was expecting all Packages, all Deliveries, or all Orders.'
    end
    self.items = items
  end

  def grouped_by_boxes
    if type.packages?
      items.group_by{|p| Box.find_or_new(p.archived_box_name)}.sort{ |a,b| a.first.name <=> b.first.name}
    elsif type.deliveries?
      items.group_by{|p| Box.find_or_new(p.package.archived_box_name)}.sort{ |a,b| a.first.name <=> b.first.name}
    elsif type.orders?
      items.group_by{|p| Box.find_or_new(p.box.name)}.sort{ |a,b| a.first.name <=> b.first.name}
    else
      raise "Shouldn't have reached this part - #{type.inspect}"
    end
  end

  def grouped_by_addresses
    items.group_by{ |delivery| delivery.package.address_hash }
  end

  class Box
    attr_accessor :name
    def initialize(name)
      self.name = name
    end

    def self.find_or_new(name)
      @boxes ||= {}

      if @boxes.has_key?(name)
        return @boxes[name]
      else
        box = Box.new(name)
        @boxes.merge!(name => box)
        return box
      end
    end
  end

  class Type
    def initialize(type)
      @type = type
    end

    def self.deliveries
      Type.new(:deliveries)
    end

    def self.packages
      Type.new(:packages)
    end

    def self.orders
      Type.new(:orders)
    end

    def deliveries?
      @type == :deliveries
    end

    def packages?
      @type == :packages
    end

    def orders?
      @type == :orders
    end
  end
end
