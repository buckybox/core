class Box < ActiveRecord::Base
  belongs_to :distributor

  has_many :orders

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  mount_uploader :box_image, BoxImageUploader

  # Setup accessible (or protected) attributes for your model
  attr_accessible :distributor, :name, :description, :likes, :dislikes, :price, :available_single, :available_weekly, 
    :available_fourtnightly, :box_image, :box_image_cache, :remove_box_image

  validates_presence_of :distributor, :name, :description, :price

  default_scope order(:name)
end
