class PaymentOption
  attr_accessor :option, :distributor

  delegate :valid?, to: :option, allow_nil: true

  def initialize(option, distributor)
    option = Option.new(option, distributor)
    if option.valid?
      self.option = option
    end
  end

  def apply(webstore_order)
    webstore_order.payment_method = option.to_s
    webstore_order.save!
  end

  def self.options(distributor)
    distributor.payment_options
  end

  class Option < Struct.new(:option, :distributor)
    def valid?
      distributor.payment_options_symbols.include?(method)
    end

    def method
      return nil if option.blank?
      option.to_sym
    end

    def to_s
      option.to_s
    end
  end
end
