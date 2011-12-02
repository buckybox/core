class Route < ActiveRecord::Base
  belongs_to :distributor

  attr_accessible :distributor, :name, :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday

  validates_presence_of :distributor, :name
end
