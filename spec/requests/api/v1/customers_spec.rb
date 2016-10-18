require "spec_helper"

include ApiHelpers

describe "API v1" do
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

    shared_examples_for "creating or updating a customer" do |method|
      let(:json_customer) { json_response }
      let(:customer) { Customer.last }
      let(:valid_http_code) { method == :post ? 201 : 200 }

      it_behaves_like "an authenticated API", method

      it "returns the customer" do
        json_request method, url, params, headers
        expect(response.status).to eq valid_http_code

        expected_response = JSON.parse(params)
        expected_response["id"] = customer.id
        expected_response.each do |attribute, value|
          next if attribute.in? embedable_attributes
          next if attribute == "email"
          expect(json_response.fetch(attribute)).to eq value
        end
      end

      it "returns the location of the newly created resource" do
        json_request method, url, params, headers
        expect(response.status).to eq valid_http_code

        expect(response.headers["Location"]).to eq api_v1_customer_url(id: customer.id)
      end

      context "with an empty body" do
        before { json_request method, url, '', headers }

        it "returns an error message" do
          expect(response.status).to eq 422
          expect(json_response["message"]).to eq "Invalid JSON"
        end
      end

      context "without missing attributes" do
        it "filters out the extra attributes" do
          extra_params = JSON.parse(params)
          extra_params["admin_with_super_powers"] = true

          json_request method, url, extra_params.to_json, headers
          expect(response).to be_success
        end
      end
    end

    before do
      @customers ||= Fabricate.times(2, :customer, distributor: api_distributor)
    end

    let(:model_attributes) { %w(id first_name last_name email delivery_service_id account_balance discount discount? halted? name number webstore_id webstore_name) }
    let(:embedable_attributes) { %w(address) }

    describe "GET /customers" do
      let(:url) { "#{base_url}/customers" }
      let(:json_customer) { json_response.first }

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
        expect(json_response.first["id"]).to eq customer.id
      end
    end

    describe "GET /customers/:id" do
      let(:url) { "#{base_url}/customers/#{customer.id}" }
      let(:customer) { @customers.first }
      let(:json_customer) { json_response }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "a customer"

      it "returns the customer" do
        expect(json_response["id"]).to eq customer.id
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
      let(:params) do
        <<-JSON
        {
            "first_name": "Joe",
            "last_name": "Smith",
            "email": "joe@smith.me",
            "delivery_service_id": #{delivery_service.id},
            "address": {
                "address_1": "12 Bucky Lane",
                "address_2": "",
                "suburb": "Boxville",
                "city": "Wellington",
                "postcode": "007",
                "delivery_note": "Just slip it through the catflap",
                "home_phone": "01 234 5678",
                "mobile_phone": "012 345 6789",
                "work_phone": "98 765 4321"
            }
        }
        JSON
      end

      it_behaves_like "creating or updating a customer", :post

      it "assigns a customer number" do
        json_request :post, url, params, headers

        expect(response).to be_success
        expect(Customer.find_by(email: "joe@smith.me").number).to be_present
      end

      context "with invalid attributes" do
        context "without missing attributes" do
          it "validates the delivery service ID" do
            delivery_service = Fabricate(:delivery_service, distributor: Fabricate(:distributor))
            invalid_params = JSON.parse(params)
            invalid_params["delivery_service_id"] = delivery_service.id

            json_request :post, url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(delivery_service_id)
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
            )
          end
        end
      end
    end

    describe "PUT /customers/:id" do
      let(:customer) { @customers.first }
      let(:url) { "#{base_url}/customers/#{customer.id}" }
      let(:params) do
        <<-JSON
        {
            "first_name": "Joe",
            "last_name": "Smith",
            "email": "joe@smith.me",
            "delivery_service_id": #{customer.delivery_service.id},
            "address": {
                "address_1": "12 Bucky Lane",
                "address_2": "",
                "suburb": "Boxville",
                "city": "Wellington",
                "postcode": "007",
                "delivery_note": "Just slip it through the catflap",
                "home_phone": "01 234 5678",
                "mobile_phone": "012 345 6789",
                "work_phone": "98 765 4321"
            }
        }
        JSON
      end

      it_behaves_like "creating or updating a customer", :put # TODO: replace with :patch when upgrading to Rails 4

      it "ignores the delivery service ID" do
        delivery_service = Fabricate(:delivery_service, distributor: Fabricate(:distributor))
        invalid_params = JSON.parse(params)
        invalid_params["delivery_service_id"] = delivery_service.id

        json_request :put, url, invalid_params.to_json, headers
        expect(response.status).to eq 200
        expect(customer.reload.delivery_service.id).not_to eq delivery_service.id
      end

      it "accepts partial updates" do
        json_request :put, url, '{"admin_with_super_powers": "1337"}', headers
        expect(response.status).to eq 200
      end

      it "updates existing addresses" do
        json_request :put, url, params, headers
        json_request :put, url, params.gsub("12 Bucky Lane", "13 Bucky Lane"), headers
        expect(response.status).to eq 200
        expect(customer.address.reload.address_1).to eq "13 Bucky Lane"
      end
    end
  end
end
