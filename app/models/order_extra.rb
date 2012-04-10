class OrderExtra < ActiveRecord::Base
  belongs_to :order
  belongs_to :extra

  delegate :name, to: :extra

  def to_hash
    extra.to_hash.merge(count: count)
  end
end
