require "spec_helper"

describe "API v0" do
  let(:base_url) { "http://api.test.dev/v0" }
  let(:headers) do
    {
      "key" => distributor.api_key, # FIXME change to "X-Key" or sth standard
      "secret" => distributor.api_secret, # FIXME
    }
  end
  let(:distributor) { Fabricate(:distributor) }

  shared_examples_for "an authenticated API" do
    it "requires authentication" do
      # url = "#{base_url}/customers"
      get url
      expect(response.status).to eq 401

      get url, nil, { "key" => "fuck", "secret" => "off" }
      expect(response.status).to eq 401
    end
  end

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

    let(:model_attributes) { %w(id first_name last_name email delivery_service_id) }
    let(:embedable_attributes) { %w(address) }


    describe "GET /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json.first["customer"] }

      before do
        get url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API"
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

      it_behaves_like "an authenticated API"
      it_behaves_like "a customer"

      it "returns the customer" do
        expect(json.size).to eq 1
        expect(json["customer"]["id"]).to eq customer.id
      end

      context "with a unknown ID" do
        before { get "#{url}0000", nil, headers }
        specify { expect(response).to be_not_found }
      end

      context "with a customer of another distributor" do
        before do
          distributor = Fabricate(:distributor)
          customer = Fabricate(:customer, distributor: distributor)
          get "#{base_url}/customers/#{customer.id}", nil, headers
        end

        specify { expect(response).to be_not_found }
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

      # it_behaves_like "an authenticated API", :post # FIXME

      it "returns the customer" do
        post url, params, headers
        expect(response.status).to eq 201

        expect(json.size).to eq 1

        expected_response = JSON.parse(params)
        expected_response["customer"]["id"] = customer.id
        expect(json).to eq expected_response
      end

      it "returns the expected attributes" do
        post url, params, headers
        expect(response.status).to eq 201

        expect(json_customer.keys).to eq(model_attributes | embedable_attributes)
      end

      it "returns the location of the newly created resource" do
        post url, params, headers
        expect(response.status).to eq 201

        expect(response.headers["Location"]).to eq api_v0_customer_url(id: customer.id)
      end

      context "with an empty body" do
        before { post url, '', headers }

        it "returns an error message" do
          expect(response.status).to eq 422
          expect(json["message"]).to eq "Invalid JSON"
        end
      end

      context "with missing attributes" do
        before { post url, '{}', headers }

        it "returns the missing attributes" do
          expect(response.status).to eq 422
          expect(json["errors"].keys).to match_array %w(
            email
            first_name
            delivery_service_id
            address
            address.address_1
          )
        end
      end

      context "with invalid attributes" do
        context "without missing attributes" do
          it "returns the extra attributes" do
            invalid_params = JSON.parse(params)
            invalid_params["customer"]["admin_with_super_powers"] = true

            post url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json["errors"]).to eq '{admin_with_super_powers: "unknown attr"}'
          end

          it "validates the delivery service ID" do
            delivery_service = Fabricate(:delivery_service, distributor: Fabricate(:distributor))
            invalid_params = JSON.parse(params)
            invalid_params["customer"]["delivery_service_id"] = delivery_service.id

            post url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json["errors"]).to eq '{DL ID is not yours!}'
          end
        end

        context "with missing attributes" do
          before { post url, '{"admin_with_super_powers": "1337"}', headers }

          it "returns the missing attributes" do
            expect(response.status).to eq 422
            expect(json["errors"].keys).to match_array %w(
              email
              first_name
              delivery_service_id
              address
              address.address_1
            )
          end
        end
      end
    end
  end
end
