class WebstorePayment < Form

  attr_accessor :credit_card, :payment_method
  
  def initialize(order)
    self.payment_method = order.payment_method
    self.credit_card = CreditCard.new if payment_method == 'credit_card'
  end

  def self.production?
    begin
      return Rails.env.production?
    rescue
      return false
    end
  end
end
