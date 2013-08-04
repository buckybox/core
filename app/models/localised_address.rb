class LocalisedAddress < ActiveRecord::Base
  attr_accessible :street, :city, :zip, :state
  belongs_to :addressable, polymorphic: true
  validates_presence_of :street, :city

  biggs :postal_address

  def recipient
    addressable.name
  end

  def country
    addressable.country.alpha2
  end
end
