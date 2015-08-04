class Extra < ActiveRecord::Base
  HUMANIZED_ATTRIBUTES  = {
    price_cents: "Price"
  }

  belongs_to :distributor

  validates_presence_of :distributor, :name, :unit, :price
  validates_uniqueness_of :name, scope: [:distributor_id, :unit]
  validates :unit, :name, length: { maximum: 80 }
  validates :price_cents, numericality: { greater_than_or_equal_to: -1E8, less_than: 1E8 }

  attr_accessible :distributor, :name, :unit, :price, :hidden, :visible

  monetize :price_cents

  after_create :update_distributors_boxes # This ensures that new extras are added to boxes which "include the entire catalog".  Currently the system doesn't understand the concept of "include the entire catalog" but only infers it from seeing that all extras for a given distributor are set on a given box.  This was an oversight and should be fixed in refactoring. #TODO

  scope :alphabetically, -> { order('name ASC, unit ASC') }
  scope :not_hidden,     -> { where(hidden: false) }
  scope :none,           -> { where("1 = 0") }

  def visible; !hidden; end

  def visible=(value)
    self[:hidden] = !value.to_bool
  end

  def to_hash
    { name: name, unit: unit, price: price }
  end

  def name_with_unit
    "#{name} (#{unit})"
  end

  def self.name_with_unit(hash)
    "#{hash[:name]} (#{hash[:unit]})"
  end

  def name_with_price(customer_discount = nil)
    if customer_discount
      "#{name} - #{price_with_discount(customer_discount)} (#{unit})"
    else
      "#{name} (#{price} per #{unit})"
    end
  end

  def price_with_discount(customer_discount = nil)
    OrderPrice.extras_price([self.to_hash.merge(count: 1)], customer_discount)
  end

  # Add this newly created extra onto all boxes which look like they are following
  # the "entire catalog" setting.  At the moment we can only infer that from seeing
  # all the extras available set on each particular box
  def update_distributors_boxes
    distributor.boxes.each do |box|
      box.extras << self if box.extras_allowed? && box.has_all_extras?(self)
    end
  end

private

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
end
