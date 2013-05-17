require 'spec_helper'

describe Distributor::DeliveriesController do
  as_distributor

  context :delivery_sequence_order do
    before do
      @route = Fabricate(:route, distributor: @distributor)
      @date = Date.today
      @date_string = @date.to_s
      @box = Fabricate(:box, distributor: @distributor)
      @deliveries = []
      @packages = []
      [3, 1, 2].collect { |position|
        result = delivery_and_package_for_distributor(@distributor, @route, @box, @date, position)
        @deliveries << result.delivery
        @packages << result.package
      }
    end

    it "should order deliveries based on the DSO" do
      get :index, {date: @date, view: @route.id.to_s}

      assigns[:all_deliveries].should eq(@deliveries.sort_by(&:dso))
    end

    it "should order future deliveries based on the DSO" do
      get :index, {date: @date+1.week, view: @route.id.to_s}
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
  end

  describe "POST export" do
    context 'given a list to export' do
      before do
        csv = 'this,that,and,the,other'
        export = double('export', csv: csv)
        controller.stub(:get_export) { export }
        controller.should_receive(:send_data).with(csv) { controller.render nothing: true }
      end

      after { post :export, @params }

      it 'exports csv of packages' do
        @params = { packages: [3, 5], date: '2013-04-26', screen: 'packing' }
      end

      it 'exports csv of packages' do
        @params = { deliveries: [3, 5], date: '2013-04-26', screen: 'packing' }
      end

      it 'exports csv of packages' do
        @params = { orders: [3, 5], date: '2013-04-26', screen: 'packing' }
      end
    end

    it 'redirects back to the last page if it can not export a CSV file' do
      request.env['HTTP_REFERER'] = 'where_i_came_from'
      controller.stub(:get_export) { nil }
      post :export
      response.should redirect_to 'where_i_came_from'
    end
  end
end
