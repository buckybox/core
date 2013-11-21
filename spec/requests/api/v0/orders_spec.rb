require "spec_helper"

include ApiHelpers

describe "API v0" do
  describe "orders" do
    shared_examples_for "an order" do
      it "returns the expected attributes" do
        expect(json_order.keys).to match_array model_attributes
      end
    end

    before do
      @orders ||= Fabricate.times(2, :order, customer: customer, box: box)
    end

    let(:customer) { Fabricate(:customer, distributor: distributor) }
    let(:extras) { Fabricate.times(2, :extra, distributor: distributor) }
    let(:box) { Fabricate(:box, distributor: distributor, extras: extras) }
    let(:model_attributes) { %w(id box_id customer_id active extras) }
    let(:embedable_attributes) { %w() }

    describe "GET /orders" do
      let(:url) { "#{base_url}/orders" }
      let(:json_order) { json_response.first["order"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "an order"

      it "returns the list of orders" do
        expect(json_response.size).to eq @orders.size
      end

      it "accepts a customer ID as a search query" do
        order = @orders.last
        customer = order.customer

        json_request :get, "#{url}?customer_id=#{customer.id}", nil, headers
        expect(response).to be_success
        expect(json_response.size).to eq customer.orders.size
      end

      context "with an unknown customer ID" do
        it "returns an empty result" do
          json_request :get, "#{url}?customer_id=0", nil, headers

          expect(response.status).to eq 422
          expect(json_response["errors"].keys).to match_array %w(customer_id)
        end
      end
    end

    describe "GET /orders/:id" do
      let(:url) { "#{base_url}/orders/#{order.id}" }
      let(:order) { @orders.first }
      let(:json_order) { json_response["order"] }

      before do
        json_request :get, url, nil, headers
        expect(response).to be_success
      end

      it_behaves_like "an authenticated API", :get
      it_behaves_like "an order"

      it "returns the order" do
        expect(json_response.size).to eq 1
        expect(json_response["order"]["id"]).to eq order.id
      end

      context "with a unknown ID" do
        before { json_request :get, "#{url}0000", nil, headers }
        specify { expect(response).to be_not_found }
      end

      context "with an order of another distributor" do
        before do
          order = Fabricate(:order)
          json_request :get, "#{base_url}/orders/#{order.id}", nil, headers
        end

        specify { expect(response).to be_not_found }
      end
    end

    describe "POST /orders" do
      let(:url) { "#{base_url}/orders" }
      let(:json_order) { json_response["order"] }
      let(:params) do <<-JSON
        {
          "order": {
            "box_id": #{box.id},
            "customer_id": #{customer.id},
            "extras": [
              {
                "extra": {
                  "id": #{extras.first.id},
                  "quantity": 1
                }
              },
              {
                "extra": {
                  "id": #{extras.last.id},
                  "quantity": 3
                }
              }
            ]
          }
        }
        JSON
      end

      it_behaves_like "an authenticated API", :post

      it "returns the order" do
        json_request :post, url, params, headers
        expect(response.status).to eq 201

        expect(json_response.size).to eq 1

        expected_response = JSON.parse(params)
        expected_response["order"]["id"] = Order.maximum(:id)
        expected_response["order"]["active"] = false
        expect(json_response).to eq expected_response
      end

      it "returns the expected attributes" do
        json_request :post, url, params, headers
        expect(response.status).to eq 201

        expect(json_order.keys).to match_array(model_attributes | embedable_attributes)
      end

      it "returns the location of the newly created resource" do
        json_request :post, url, params, headers
        expect(response.status).to eq 201

        expect(response.headers["Location"]).to eq api_v0_order_url(id: json_order["id"])
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
            box_id
            customer_id
          )
        end
      end

      context "with invalid attributes" do
        context "without missing attributes" do
          it "filters out the extra attributes" do
            extra_params = JSON.parse(params)
            extra_params["order"]["admin_with_super_powers"] = true

            json_request :post, url, extra_params.to_json, headers
            expect(response).to be_success
          end

          it "validates the box ID" do
            box = Fabricate(:box, distributor: Fabricate(:distributor))
            invalid_params = JSON.parse(params)
            invalid_params["order"]["box_id"] = box.id

            json_request :post, url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(box_id)
          end

          it "validates the customer ID" do
            customer = Fabricate(:customer, distributor: Fabricate(:distributor))
            invalid_params = JSON.parse(params)
            invalid_params["order"]["customer_id"] = customer.id

            json_request :post, url, invalid_params.to_json, headers
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(customer_id)
          end
        end

        context "with missing attributes" do
          before { json_request :post, url, '{"admin_with_super_powers": "1337"}', headers }

          it "returns the missing attributes" do
            expect(response.status).to eq 422
            expect(json_response["errors"].keys).to match_array %w(
              box_id
              customer_id
            )
          end
        end
      end
    end
  end
end

