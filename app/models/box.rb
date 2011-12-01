class Box < ActiveRecord::Base
  belongs_to :distributor

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  mount_uploader :box_image, BoxImageUploader

  # Setup accessible (or protected) attributes for your model
  attr_accessible :name, :description, :likes, :dislikes, :price, :available_single, :available_weekly, 
    :available_fourtnightly, :box_image

  validates_presence_of :name, :description, :price
end
