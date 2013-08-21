class LocalisedAddress < ActiveRecord::Base
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
