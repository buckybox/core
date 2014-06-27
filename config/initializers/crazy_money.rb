# define Money Gem drop-in `monetize` helper
class ActiveRecord::Base
  class << self
    def monetize attribute_cents
      attribute = attribute_cents.to_s.sub(/_cents$/, "")

      define_method attribute do
        CrazyMoney.new(send(attribute_cents)) / 100
      end

      define_method "#{attribute}=" do |value|
        send("#{attribute_cents}=", CrazyMoney.new(value).cents.to_i)
      end
    end
  end
end

# make CrazyMoney objects decoratable with Draper
CrazyMoney.send(:include, Draper::Decoratable)

