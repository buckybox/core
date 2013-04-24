class CreditCard < Form

  ATTRS = :card_brand, :card_number, :name_on_card, :first_name, :last_name, :expiry_month, :expiry_year, :card_security_code, :store_for_future_use
  ATTRS.each do |attr|
    attr_accessor attr
  end
  
  def initialize(args={})
    ATTRS.each do |attr|
      self.send("#{attr.to_s}=", args[attr]) if args[attr].present?
    end
    self.store_for_future_use = self.store_for_future_use == 1
  end

  def self.production?
    begin
      return Rails.env.production?
    rescue
      return false
    end
  end

  def self.card_brands
  ['Mastercard', 'Visa']
  end

  def authorize!(webstore_order)
    
  end

  def purchase!(webstore_order)
    return false if !valid?
    
    gateway = ActiveMerchant::Billing::BraintreeGateway.new(
      login: 'demo',
      password: 'password'
    )

    response = gateway.purchase(webstore_order.order_price, to_active_merchant_cc)
    return response
  end

  def authorize!(webstore_order)
    
  end

  def self.months
    1.upto(12).to_a
  end

  def self.years
    current_year = Time.current.year
    0.upto(10).collect{|i| current_year + i}
  end

  def card_brand
    @card_brand || 'Visa'
  end

  def valid?
    active_merchant_cc.valid?
  end

  def errors
    active_merchant_cc.errors
  end

  def name_on_card
    @name_on_card || ''
  end
  
  def active_merchant_cc
    @active_merchant_cc ||= to_active_merchant_cc
  end

  def to_active_merchant_cc
    ActiveMerchant::Billing::CreditCard.new({
      first_name: first_name,
      last_name: last_name,
      number: card_number,
      month: expiry_month,
      year: expiry_year,
      verification_value: card_security_code,
      brand: card_brand
    })
  end

end
