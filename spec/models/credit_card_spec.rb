require 'fast_spec_helper'
require 'date'

require 'active_support/core_ext'

require 'active_model/naming'
require 'active_model/conversion'

require 'rubygems'
require 'active_merchant'
require 'pry'

require_model 'credit_card'
#require_constants %w()

describe CreditCard do
  it 'should be invalid' do
    invalid_credit_card.should_not be_valid
  end

  it 'should be valid' do
    valid_credit_card.should be_valid, valid_credit_card.errors.full_messages.join(', ')
  end
end

def invalid_credit_card(opts={})
  CreditCard.new({
    card_type: :visa,
    card_number: '5111111111111111',
    first_name: 'Jordan',
    last_name: 'Carter',
    expiry_month: '03',
    expiry_year: Date.today.year + 4,
    card_security_code: 987,
    store_for_future_use: false
  }.merge(opts))
end

def valid_credit_card(opts={})
  CreditCard.new({
    card_type: :visa,
    card_number: '4111111111111111',
    first_name: 'Jordan',
    last_name: 'Carter',
    expiry_month: '03',
    expiry_year: Date.today.year + 4,
    card_security_code: 987,
    store_for_future_use: false
  }.merge(opts))
end
