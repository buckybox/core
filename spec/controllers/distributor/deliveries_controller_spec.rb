require 'spec_helper'

describe Distributor::DeliveriesController do
  sign_in_as_distributor

  describe "delivery sequence order" do
    before do
      @delivery_service = Fabricate(:delivery_service, distributor: @distributor)
      @date = Date.today
      @date_string = @date.to_s
      @box = Fabricate(:box, distributor: @distributor)
      @deliveries = []
      @packages = []
      [3, 1, 2].collect do |position|
        result = delivery_and_package_for_distributor(@distributor, @delivery_service, @box, @date, position)
        @deliveries << result.delivery
        @packages << result.package
      end
    end

    it "should order deliveries based on the DSO" do
      get :index, { date: @date, view: @delivery_service.id.to_s }

      expect(assigns[:all_deliveries]).to eq(@deliveries.sort_by(&:dso))
    end

    it "should order future deliveries based on the DSO" do
      get :index, { date: @date + 1.week, view: @delivery_service.id.to_s }
      expect(assigns[:all_deliveries]).to eq(@deliveries.sort_by(&:dso).collect(&:order))
    end

    it "should update the position of a delivery when placed between two others" do
      delivery_list = mock_model(DeliveryList)
      delivery_ids = %w(2 1 3)
      expect(delivery_list).to receive(:reposition).with(delivery_ids)
      delivery_lists = double('DeliveryLists')
      allow(delivery_lists).to receive(:find_by_date).with(@date_string).and_return(delivery_list)
      allow_any_instance_of(Distributor).to receive(:delivery_lists).and_return(delivery_lists)

      post :reposition, { date: @date_string, delivery: delivery_ids }
    end
  end
end
