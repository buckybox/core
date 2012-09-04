module ApplicationHelper
  FEATURED_CURRENCIES = [:gbp, :aud, :hkd, :usd, :nzd]

  def currency_name(key)
    hash = currency_hash
    hash[key.downcase.to_sym]
  end

  def currency_hash
    @currency_hash ||= Money::Currency.table.each_with_object({}) { |(k,v), h| h[k] = "#{v[:name]} (#{v[:iso_code]})" }
  end

  def select_currencies
    hash = currency_hash
    currencies = FEATURED_CURRENCIES.each_with_object([]) { |fc, a| a << [hash.delete(fc), fc] }
    currencies += hash.invert.to_a
    currencies.collect{|a,b| [a, b.to_s.upcase]}
  end
end
