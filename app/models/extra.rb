class Extra < ActiveRecord::Base
  belongs_to :distributor

  FUZZY_MATCH_THRESHOLD = 0.8

  validates_presence_of :distributor, :name, :unit, :price

  attr_accessible :distributor, :name, :unit, :price
  scope :alphabetically, order('name ASC, unit ASC')

  monetize :price_cents

  after_create :update_distributors_boxes # This ensures that new extras are added to boxes which "include the entire catalog".  Currently the system doesn't understand the concept of "include the entire catalog" but only infers it from seeing that all extras for a given distributor are set on a given box.  This was an oversight and should be fixed in refactoring. #TODO

  def to_hash
    { name: name, unit: unit, price_cents: price_cents, currency: currency }
  end

  def name_with_unit
    "#{name} (#{unit})"
  end

  def name_with_price(customer_discount)
    "#{name} - #{price_with_discount(customer_discount).format} (#{unit})"
  end

  def price_with_discount(customer_discount)
    Package.calculated_extras_price([self.to_hash.merge(count: 1)], customer_discount)
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
end
