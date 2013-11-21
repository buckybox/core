require "spec_helper"

include ApiHelpers

describe "API v0" do
  let(:delivery_service) { Fabricate(:delivery_service, distributor: api_distributor) }

  describe "customers" do
    shared_examples_for "a customer" do
      it "returns the expected attributes" do
        expect(json_customer.keys).to match_array model_attributes
      end

      it "returns embedable attributes" do
        json_request :get, "#{url}?embed=#{embedable_attributes.join(',')}", nil, headers

        expect(response).to be_success
        expect(json_customer.keys).to match_array(model_attributes | embedable_attributes)
      end
    end

    before do
      @customers ||= Fabricate.times(2, :customer, distributor: api_distributor)
    end

    let(:model_attributes) { %w(id first_name last_name email delivery_service_id) }
    let(:embedable_attributes) { %w(address) }

    describe "GET /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json_response.first["customer"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a customer"

      it "returns the list of customers" do
        expect(json_response.size).to eq @customers.size
      end

      it "accepts an email as a search query" do
        customer = @customers.last

        json_request :get, "#{url}?email=#{customer.email}", nil, headers
        expect(response).to be_success
        expect(json_response.size).to eq 1
        expect(json_response.first["customer"]["id"]).to eq customer.id
      end
    end

    describe "GET /customers/:id" do
      let(:url) { "#{base_url}/customers/#{customer.id}" }
      let(:customer) { @customers.first }
      let(:json_customer) { json_response["customer"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a customer"

      it "returns the customer" do
        expect(json_response.size).to eq 1
        expect(json_response["customer"]["id"]).to eq customer.id
      end

      context "with a unknown ID" do
        before { json_request :get, "#{url}0000", nil, headers }
        specify { expect(response).to be_not_found }
      end

      context "with a customer of another distributor" do
        before do
          new_distributor = Fabricate(:distributor)
          customer = Fabricate(:customer, distributor: new_distributor)
          json_request :get, "#{base_url}/customers/#{customer.id}", nil, headers
        end

        specify { expect(response).to be_not_found }
      end
    end

    describe "POST /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json_response["customer"] }
      let(:customer) { Customer.last }
      let(:params) do <<-JSON
        {
          "customer": {
              "first_name": "Will",
              "last_name": "Lau",
              "email": "will@buckybox.com",
              "delivery_service_id": #{delivery_service.id},
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
        }
        JSON
      end

      it_behaves_like "an authenticated API", :post

      it "returns the customer" do
        json_request :post, url, params, headers
        expect(response.status).to eq 201

        expect(json_response.size).to eq 1

        expected_response = JSON.parse(params)
        expected_response["customer"]["id"] = customer.id
        expect(json_response).to eq expected_response
      end

      it "returns the location of the newly created resource" do
        json_request :post, url, params, headers
        expect(response.status).to eq 201

        expect(response.headers["Location"]).to eq api_v0_customer_url(id: customer.id)
      end

      context "with an empty body" do
        before { json_request :post, url, '', headers }

        it "returns an error message" do
          expect(response.status).to eq 422
          expect(json_response["message"]).to eq "Invalid JSON"
        end
      end

      context "with missing attributes" do
        before { json_request :post, url, '{}', headers }

        it "returns the missing attributes" do
          expect(response.status).to eq 422
          expect(json_response["errors"].keys).to match_array %w(
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
          it "filters out the extra attributes" do
            extra_params = JSON.parse(params)
            extra_params["customer"]["admin_with_super_powers"] = true

            json_request :post, url, extra_params.to_json, headers
            expect(response).to be_success
          end

          it "validates the delivery service ID" do
            delivery_service = Fabricate(:delivery_service, distributor: Fabricate(:distributor))
            invalid_params = JSON.parse(params)
            invalid_params["customer"]["delivery_service_id"] = delivery_service.id

            json_request :post, url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(delivery_service_id)
          end
        end

        context "with missing attributes" do
          before { json_request :post, url, '{"admin_with_super_powers": "1337"}', headers }

          it "returns the missing attributes" do
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(
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
