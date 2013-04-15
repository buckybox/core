class PaymentOptionsForm
  attr_accessor :webstore_order, :form

  def initialize(args={})
    self.webstore_order = args[:webstore_order]
    self.form = args[:form]
  end

  def options
    PaymentOption.options
  end
end
