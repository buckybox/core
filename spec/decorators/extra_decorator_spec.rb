require 'fast_spec_helper'
stub_constants %w(Extra)
require_relative '../../app/decorators/extra_decorator'
Draper::ViewContext.test_strategy :fast

describe ExtraDecorator do
  include Draper::ViewHelpers

  let(:object) { double('object') }
  let(:extra_decorator) { ExtraDecorator.new(object) }

  describe '#with_unit' do
    it 'returns a string with the extra name and unit' do
      object.stub(:name) { 'Extra' }
      object.stub(:unit) { 1 }
      extra_decorator.with_unit.should { 'Extra (1)' }
    end
  end
end
