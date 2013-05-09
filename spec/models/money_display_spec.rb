require 'fast_spec_helper'

require_model 'money_display'
require 'money'

describe MoneyDisplay do

  let(:positive_money){Money.new(2312)}
  let(:negative_money){Money.new(-65465)}

  it 'should display money formatted' do
    MoneyDisplay.new(positive_money).to_s.should eq('$23.12')
  end

  it 'should add brackets to negative numbers' do
    MoneyDisplay.new(negative_money).to_s.should eq('($654.65)')
  end

  it 'should not accept objects which arent money ducks (respond to .format)' do
    expect{MoneyDisplay.new(12)}.to raise_error("Object must respond to .format")
  end

  it 'should return the negative version of itself' do
    MoneyDisplay.new(positive_money).negative.obj.should eq(-23.12)
  end
end
