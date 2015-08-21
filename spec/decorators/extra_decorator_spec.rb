require 'spec_helper'

describe ExtraDecorator do
  let(:object) { double('object') }
  let(:extra_decorator) { ExtraDecorator.new(object) }

  describe '#with_unit' do
    it 'returns a string with the extra name and unit' do
      allow(object).to receive(:name) { 'Extra' }
      allow(object).to receive(:unit) { 1 }
      expect(extra_decorator.with_unit).to eq 'Extra (1)'
    end
  end
end
