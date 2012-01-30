require 'spec_helper'

describe DeliveryList do
  before { @delivery_list = Fabricate(:delivery_list) }

  specify { @delivery_list.should be_valid }
end
