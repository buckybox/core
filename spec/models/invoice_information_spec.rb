require 'spec_helper'

describe InvoiceInformation do
  let(:invoice_information) { Fabricate(:invoice_information) }

  specify { expect(invoice_information).to be_valid }
end

