class Box < ActiveRecord::Base
  belongs_to :distributor

  has_many :orders
  has_many :box_extras
  has_many :extras, through: :box_extras

  mount_uploader :box_image, BoxImageUploader

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor, :name, :description, :likes, :dislikes, :price, :available_single, :available_weekly,
    :available_fourtnightly, :box_image, :box_image_cache, :remove_box_image, :extras_limit, :extra_ids, :hidden

  validates_presence_of :distributor, :name, :description, :price
  validates :extras_limit, numericality: { greater_than: -2 }

  monetize :price_cents

  default_value_for :extras_limit, 0

  default_scope order(:name)
  scope :not_hidden, where(hidden: false)

  # [["disable extras", 0], ["allow any number of extra items", -1],
  # ["allow 1 extra items", 1], ["allow 2 extra items", 2], ... ["allow n extra items, n]]
  SPECIAL_EXTRA_OPTIONS = ['disable extras', 'allow any number of extra items'].zip([0, -1])
  COUNT_EXTRA_OPTIONS = 1.upto(10).map{ |i| "allow #{i} extra items" }.zip(1.upto(10).to_a)
  EXTRA_OPTIONS = (SPECIAL_EXTRA_OPTIONS + COUNT_EXTRA_OPTIONS)

  def big_thumb_url
    box_image.big_thumb.url
  end

  def customisable?
    dislikes? || extras_allowed?
  end

  def extras_unlimited?
    extras_limit == -1
  end

  def extras_not_allowed?
    (extras_limit.blank? || extras_limit.zero?)
  end

  def extras_allowed?
    !extras_not_allowed?
  end

  def extra_option
    if extras_unlimited?
      "any number of extras"
    elsif extras_disabled?
      "disabled"
    elsif extras_limit == 1
      "1 extra allowed"
    else
      "#{extras_limit} extras allowed"
    end
  end

  def extras_disabled?
    extras_limit == 0
  end

  def has_all_extras?(exclude=[])
    exclude = [exclude] unless exclude.is_a?(Array)
    (distributor.extras - exclude).sort == extras.sort
  end

  # Used to select which drop down value is selected
  # on extras form
  def all_extras?
    if new_record? || extras_disabled? # By default show 'from the entire extras catalog'
      true
    elsif distributor.present?
      has_all_extras?
    else
      false
    end
  end
  alias :all_extras :all_extras? # I prefer to have '?' on the end of methods but simple_form won't take it as an attribute
end
