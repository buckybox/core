class WebstorePayment < Form

  attr_accessor :credit_card
  
  def initialize(args={})
    self.credit_card = CreditCard.new
  end

  def self.production?
    begin
      return Rails.env.production?
    rescue
      return false
    end
  end
end
