class Country < ActiveRecord::Base
  attr_accessible :default_currency, :default_consumer_fee, :default_time_zone, :name

  has_many :distributors

  validate :currency_and_time_zone
  
  private
  def currency_and_time_zone
    errors.add(:default_time_zone, "'#{default_time_zone}' not valid") if ActiveSupport::TimeZone.new(default_time_zone).nil?
    begin
      Money.parse(default_currency)
    rescue
      errors.add(:default_currency, "'#{default_currency}' not valid")
    end
  end
end
