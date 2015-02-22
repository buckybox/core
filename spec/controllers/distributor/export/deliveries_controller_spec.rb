require 'spec_helper'

describe Distributor::Export::DeliveriesController do
  sign_in_as_distributor

  context 'given a list to export' do
    before do
      csv = 'this,that,and,the,other'
      export = double('export', csv: csv)
      allow(Distributor::Export::Utils).to receive(:get_export) { export }
      expect(controller).to receive(:send_data).with(csv) { controller.render nothing: true }
    end

    after { post :index, @params }

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
    allow(controller).to receive(:get_export) { nil }
    post :index
    expect(response).to redirect_to 'where_i_came_from'
  end
end
