class PaymentOption
  PAID = 'paid'.freeze

  attr_accessor :option, :distributor

  delegate :valid?, to: :option, allow_nil: true

  def initialize(option, distributor)
    raise "distributor is nil" unless distributor

    option = Option.new(option, distributor)
    self.option = option if option.valid?
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

    delegate :to_s, to: :option

    def description
      distributor.payment_options.each do |description, symbol|
        return description if symbol == method
      end

      nil
    end
  end
end
