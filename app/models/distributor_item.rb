class DistributorItem < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :name

  validates_presence_of :distributor, :name
end
