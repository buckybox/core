require 'spec_helper'

describe InvoiceInformation do
  before do
    @invoice_information = InvoiceInformation.make
  end

  specify { @invoice_information.should be_valid }
end

