require "spec_helper"

describe "API v0" do
  describe "customers" do
    before do
      distributor.generate_api_key!
      @customers ||= Fabricate.times(2, :customer, distributor: distributor)
    end

    let(:api_url) { "http://api.test.dev/v0" }
    let(:headers) do
      {
        "key" => distributor.api_key, # FIXME change to "X-Key" or sth standard
        "secret" => distributor.api_secret, # FIXME
      }
    end

    let(:distributor) { Fabricate(:distributor) }
    let(:expected_attributes) { %w(id first_name last_name email delivery_service_id) }

    describe "GET /customers" do
      before do
        get "#{api_url}/customers", nil, headers
        expect(response).to be_success
      end

      it "returns the list of customers" do
        expect(json.size).to eq @customers.size
      end

      it "returns the expected attributes" do
        customer = json.first["customer"]

        expect(customer.keys).to eq expected_attributes
      end

      it "accepts an email as a search query" do
        customer = @customers.last

        get "#{api_url}/customers?email=#{customer.email}", nil, headers
        expect(response).to be_success
        expect(json.size).to eq 1
        expect(json.first["customer"]["id"]).to eq customer.id
      end
    end

    describe "GET /customers/:id" do
      let(:customer) { @customers.first }

      before do
        get "#{api_url}/customers/#{customer.id}", nil, headers
        expect(response).to be_success
      end

      it "returns the customer" do
        expect(json.size).to eq 1
        expect(json["customer"]["id"]).to eq customer.id
      end

      it "returns the expected attributes" do
        customer = json["customer"]

        expect(customer.keys).to eq expected_attributes
      end
    end
  end
end
