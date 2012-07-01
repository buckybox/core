class Substitution < ActiveRecord::Base
  belongs_to :order
  belongs_to :line_item

  has_one :customer, through: :order

  attr_accessible :order, :line_item

  validates_presence_of :order, :line_item
  validates_uniqueness_of :line_item_id, scope: :order_id

  def self.change_line_items!(old_line_item, new_line_item)
    old_line_item.substitutions.each do |s|
      s.update_attribute(:line_item_id, new_line_item.id)
      s.save
    end
  end
end
