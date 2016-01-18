class LocalisedAddress < ActiveRecord::Base
  attr_accessible :street, :city, :zip, :state, :lat, :lng
  belongs_to :addressable, polymorphic: true
  validates_presence_of :street, :city

  biggs :postal_address

  after_save :geocode_async, if: "changed?"

  def recipient
    addressable.name
  end

  def country
    addressable.country.alpha2
  end

  def postal_address_with_recipient
    postal_address
  end

  def postal_address_without_recipient
    biggs_values = biggs_values_without([:recipient])
    Biggs::Formatter.new.format(country, biggs_values).strip
  end

  def ll
    [lat, lng]
  end

private

  def geocode_async
    delay(
      priority: Figaro.env.delayed_job_priority_high,
      queue: "#{__FILE__}:#{__LINE__}",
    ).geocode
  end

  def geocode
    # XXX: the record might no longer exist when DJ runs this
    return unless self.class.exists?(id)

    geocoded_address = nil

    address_in_sections.detect do |address_parts|
      full_address = address_parts.join(" ").squeeze(" ")
      geocoded_address = geocode_address(full_address)
      geocoded_address.success
    end

    return unless geocoded_address

    # bypass callbacks to avoid infinite loop
    update_column(:lat, geocoded_address.lat)
    update_column(:lng, geocoded_address.lng)
  end

  def address_in_sections
    [
      postal_address_without_recipient.split("\n"),
      [street, city, zip, state, country],
      [city, zip, country],
      [country],
    ]
  end

  def geocode_address(address)
    # NOTE: Google allows up to 10 requests per second
    # https://developers.google.com/maps/documentation/geocoding/?csw=1#Limits
    Retryable.retryable(tries: 3, sleep: 2, on: Geokit::Geocoders::TooManyQueriesError) do
      Geokit::Geocoders::GoogleGeocoder.geocode address
    end
  end

  def biggs_values_without(fields)
    values = {}
    (Biggs::Formatter::FIELDS - fields).each do |field|
      values[field] = biggs_get_value(field)
    end
    values
  end
end
