class PaymentOption
  attr_accessor :option

  delegate :valid?, to: :option, allow_nil: true

  def initialize(option)
    option = Option.new(option)
    if option.valid?
      self.option = option
    end
  end

  def apply(webstore_order)
    webstore_order.payment_method = option.to_s
    webstore_order.save!
  end

  def self.options
    [["Credit card", :credit_card],
    ["Bank deposit", :bank_deposit],
    ["Cash on delivery", :cash_on_delivery]]
  end

  class Option < Struct.new(:option)
    def valid?
      [:credit_card, :bank_deposit, :cash_on_delivery].include?(method)
    end

    def method
      option.to_sym
    end

    def to_s
      option.to_s
    end
  end
end
