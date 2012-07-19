require 'spec_helper'

describe Distributor::DeliveriesController do
  as_distributor
  
  context :delivery_sequence_order do
    it "should order deliveries based on the DSO" do
      @route = Fabricate(:route, distributor: @distributor)
      @date = Date.today
      @box = Fabricate(:box, distributor: @distributor)
      @deliveries = 3.times.collect { |i|
        delivery_for_distributor(@distributor, @route, @box, @date)
      }
      
      get :index

      assigns[:all_deliveries].should eq(@deliveries)
    end
  end
end
