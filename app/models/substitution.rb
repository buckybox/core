class Substitution < ActiveRecord::Base
  belongs_to :order
  belongs_to :line_item

  has_one :customer, through: :order

  attr_accessible :order, :line_item

  validates_presence_of :order, :line_item
  validates_uniqueness_of :line_item_id, scope: :line_item_id
end
