class OrderExtra < ActiveRecord::Base
  belongs_to :order
  belongs_to :extra

  #TODO: Should there be validations of order extra here?
  validates_numericality_of :count, greater_than: 0

  scope :none, where("1 = 0")
  delegate :name, to: :extra

  def to_hash
    extra.to_hash.merge(count: count)
  end
end
