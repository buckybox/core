require "spec_helper"

describe "API v0" do
  describe "customers" do
    shared_examples_for "a customer" do
      it "returns the expected attributes" do
        expect(json_customer.keys).to eq model_attributes
      end

      it "returns embedable attributes" do
        get "#{url}?embed=#{embedable_attributes.join(',')}", nil, headers

        expect(response).to be_success
        expect(json_customer.keys).to eq(model_attributes | embedable_attributes)
      end
    end

    before do
      distributor.generate_api_key!
      @customers ||= Fabricate.times(2, :customer, distributor: distributor)
    end

    let(:base_url) { "http://api.test.dev/v0" }
    let(:headers) do
      {
        "key" => distributor.api_key, # FIXME change to "X-Key" or sth standard
        "secret" => distributor.api_secret, # FIXME
      }
    end

    let(:distributor) { Fabricate(:distributor) }
    let(:model_attributes) { %w(id first_name last_name email delivery_service_id) }
    let(:embedable_attributes) { %w(address) }

    describe "GET /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json.first["customer"] }

      before do
        get url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "a customer"

      it "returns the list of customers" do
        expect(json.size).to eq @customers.size
      end

      it "accepts an email as a search query" do
        customer = @customers.last

        get "#{url}?email=#{customer.email}", nil, headers
        expect(response).to be_success
        expect(json.size).to eq 1
        expect(json.first["customer"]["id"]).to eq customer.id
      end
    end

    describe "GET /customers/:id" do
      let(:url) { "#{base_url}/customers/#{customer.id}" }
      let(:customer) { @customers.first }
      let(:json_customer) { json["customer"] }

      before do
        get url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "a customer"

      it "returns the customer" do
        expect(json.size).to eq 1
        expect(json["customer"]["id"]).to eq customer.id
      end
    end

    describe "POST /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json["customer"] }
      let(:customer) { Customer.last }
      let(:params) do
        '{
          "customer": {
              "first_name": "Will",
              "last_name": "Lau",
              "email": "will@buckybox.com",
              "delivery_service_id": 56,
              "address": {
                  "address_1": "12 Bucky Lane",
                  "address_2": "",
                  "suburb": "Boxville",
                  "city": "Wellington",
                  "delivery_note": "Just slip it through the catflap",
                  "home_phone": "01 234 5678",
                  "mobile_phone": "012 345 6789",
                  "work_phone": "98 765 4321"
              }
          }
        }'
      end

      before do
        post url, params, headers
        expect(response.status).to eq 201
      end

      it "returns the customer" do
        expect(json.size).to eq 1

        expected_response = JSON.parse(params)
        expected_response["customer"]["id"] = customer.id
        expect(json).to eq expected_response
      end

      it "returns the expected attributes" do
        expect(json_customer.keys).to eq(model_attributes | embedable_attributes)
      end

      it "returns the location of the newly created resource" do
        expect(response.headers["Location"]).to eq api_v0_customer_url(id: customer.id)
      end
    end
  end
end
