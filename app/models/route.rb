class Route < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday, :distributor

  validates_presence_of :name
end
