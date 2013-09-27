class Country < ActiveRecord::Base
  attr_accessible :alpha2, :default_consumer_fee_cents

  validates_presence_of :alpha2
  validate :validate_currency_and_time_zone

  delegate :name, to: :iso3166
  alias_method :full_name, :name

  def default_currency
    @default_currency ||= iso3166.currency.code
  end

  def time_zones
    return @time_zones if @time_zones

    begin
      time_zones = TZInfo::Country.get(alpha2).zone_names
    rescue TZInfo::InvalidCountryCode
      # noop
    end

    time_zones = ["Etc/UTC"] if time_zones.blank?

    @time_zones ||= time_zones
  end

  def default_time_zone
    @default_time_zone ||= time_zones.first
  end

  def iso3166
    @iso3166 ||= ISO3166::Country.new alpha2
  end

private

  def validate_currency_and_time_zone
    if ActiveSupport::TimeZone.new(default_time_zone).nil?
      errors.add(:default_time_zone, "'#{default_time_zone}' not valid")
    end

    if CurrencyData.find(default_currency).nil?
      errors.add(:default_currency, "'#{default_currency}' not valid")
    end
  end
end
