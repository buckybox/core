class ActiveRecord::Base
  class << self
    def monetize attribute_cents
      attribute = attribute_cents.to_s.sub(/_cents$/, "")

      define_method attribute do
        EasyMoney.new(send(attribute_cents)) / 100.0
      end

      define_method "#{attribute}=" do |value|
        send("#{attribute_cents}=", EasyMoney.new(value).cents.to_i)
      end
    end
  end
end

