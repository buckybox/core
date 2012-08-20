require 'spec_helper'

describe Distributor::DeliveriesController do
  as_distributor
  
  context :delivery_sequence_order do
    before do
      @route = Fabricate(:route, distributor: @distributor)
      @date = Date.today
      @date_string = @date.to_s
      @box = Fabricate(:box, distributor: @distributor)
      @deliveries = [3, 1, 2].collect { |position|
        delivery_for_distributor(@distributor, @route, @box, @date, position)
      }
    end
    
    it "should order deliveries based on the DSO" do
      get :index, {date: @date, view: 'deliveries'}

      assigns[:all_deliveries].should eq(@deliveries.sort_by(&:dso))
    end

    it "should order future deliveries based on the DSO" do
      get :index, {date: @date+1.week, view: 'deliveries'}
      assigns[:all_deliveries].should eq(@deliveries.sort_by(&:dso).collect(&:order))
    end

    it "should update the position of a delivery when placed between two others" do
      delivery_list = mock_model(DeliveryList)
      delivery_ids = ['2', '1', '3']
      delivery_list.should_receive(:reposition).with(delivery_ids)
      delivery_lists = mock('DeliveryLists')
      delivery_lists.stub(:find_by_date).with(@date_string).and_return(delivery_list)
      Distributor.any_instance.stub(:delivery_lists).and_return(delivery_lists)

      post :reposition, {date: @date_string, delivery: delivery_ids}
    end

    it "should order csv based on DSO" do
      Delivery.should_receive(:build_csv_for_export).with(:delivery, @distributor, ["1","2","6"], nil).and_return("")

      post :export, {deliveries: [1,2,6]}
    end
  end
end
