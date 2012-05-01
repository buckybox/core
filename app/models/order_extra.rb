class OrderExtra < ActiveRecord::Base
  belongs_to :order
  belongs_to :extra

  delegate :name, to: :extra
  validates :count, numericality: {greater_than: 0}

  def to_hash
    extra.to_hash.merge(count: count)
  end
end
