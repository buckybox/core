require 'spec_helper.rb'

describe Distributor::ReportsController do
  sign_in_as_distributor

  describe '#index' do
    it 'renders the right template' do
      get :index, distributor_id: @distributor.id
      response.should render_template 'distributor/reports/index'
    end
  end

  shared_examples 'a csv export' do |action, csv_generator|
    let(:csv_object)  { double('csv_object', data: 'data', name: 'name') }

    before do
      csv_generator.stub(:new) { csv_object }
      post action
    end

    it "downloads a csv" do
      expect(response.headers['Content-Type']).to eq('text/csv; charset=utf-8; header=present')
    end

    it "provides the data" do
      expect(response.body).to eq('data')
    end

    it "provides a filename" do
      expect(response.headers['Content-Disposition']).to eq('attachment; filename="name.csv"')
    end
  end

  describe 'exporting' do
    describe '#transaction_history' do
      it_behaves_like('a csv export', :transaction_history, Report::TransactionHistory)
    end

    describe '#customer_account_history' do
      it_behaves_like('a csv export', :customer_account_history, Report::CustomerAccountHistory)
    end
  end
end
