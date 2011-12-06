require 'spec_helper'

describe InvoiceInformation do
  before :all do
    @invoice_information = Fabricate(:invoice_information)
  end

  specify { @invoice_information.should be_valid }
end

