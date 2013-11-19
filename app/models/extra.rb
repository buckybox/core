class Extra < ActiveRecord::Base
  FUZZY_MATCH_THRESHOLD = 0.8
  HUMANIZED_ATTRIBUTES  = {
    price_cents: "Price"
  }

  belongs_to :distributor

  validates_presence_of :distributor, :name, :unit, :price
  validates :unit, :name, length: {maximum: 80}
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, less_than: 1E8 }

  attr_accessible :distributor, :name, :unit, :price, :hidden, :visible

  monetize :price_cents

  after_create :update_distributors_boxes # This ensures that new extras are added to boxes which "include the entire catalog".  Currently the system doesn't understand the concept of "include the entire catalog" but only infers it from seeing that all extras for a given distributor are set on a given box.  This was an oversight and should be fixed in refactoring. #TODO

  scope :alphabetically, order('name ASC, unit ASC')
  scope :not_hidden, where(hidden: false)
  scope :none, where("1 = 0")

  def visible; !hidden; end

  def visible=(value)
    write_attribute(:hidden, !value.to_bool)
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

  def match_import_extra?(extra)
    Bucky::Util.fuzzy_match(name, extra.name) > FUZZY_MATCH_THRESHOLD &&
      (extra.unit.blank? || Bucky::Util.fuzzy_match(extra.unit.gsub(/ +/,''), extra.unit.gsub(/ +/,'')))
  end

  def fuzzy_match(extra)
    return 0 if extra.blank?

    match = 1.0
    name_match = Bucky::Util.fuzzy_match(name, extra.name)
    match *= name_match

    if extra.unit.blank?
      match *= 1.0 # If the unit was missed, assume to match any unit
    else
      unit_match = Bucky::Util.fuzzy_match(unit.gsub(/ +/,''), extra.unit.gsub(/ +/,'')) # Ignore extra and missing spaces ' '
      match *= (0.9+(unit_match*0.1)) # Reduce impact of a poor unit match
    end

    return match
  end

  # Add this newly created extra onto all boxes which look like they are following
  # the "entire catalog" setting.  At the moment we can only infer that from seeing
  # all the extras available set on each particular box
  def update_distributors_boxes
    distributor.boxes.each do |box|
      if box.extras_allowed? && box.has_all_extras?(self)
        box.extras << self
      end
    end
  end

private

  def self.human_attribute_name(attr, options = {})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end
end
