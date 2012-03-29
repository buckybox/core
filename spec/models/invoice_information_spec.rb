require 'spec_helper'

describe InvoiceInformation do
  let(:invoice_information) { Fabricate.build(:invoice_information) }

  specify { invoice_information.should be_valid }
end

