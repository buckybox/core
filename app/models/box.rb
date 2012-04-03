class Box < ActiveRecord::Base
  belongs_to :distributor

  has_many :orders
  has_many :box_extras
  has_many :extras, through: :box_extras

  mount_uploader :box_image, BoxImageUploader

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor, :name, :description, :likes, :dislikes, :price, :available_single, :available_weekly, 
    :available_fourtnightly, :box_image, :box_image_cache, :remove_box_image, :extras_limit, :extra_ids

  validates_presence_of :distributor, :name, :description, :price
  validates :extras_limit, numericality: { greater_than: -2 }

  default_scope order(:name)
  
  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  EXTRA_OPTIONS = ["No", "Limited", "Unlimited"]
  def extra_option(include_count = false)
    if extras_limit.blank? || extras_limit.zero?
      "No"
    elsif extras_limit == -1
      "Unlimited"
    else
      include_count ? "Limited(#{extras_limit})" : "Limited"
    end
  end
end
