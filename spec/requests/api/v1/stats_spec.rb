require "spec_helper"

include ApiHelpers

describe "API v1" do
  describe "stats" do
    describe "GET /conversion-pipeline" do
      let(:url) { "#{base_url}/conversion-pipeline?from=2015-06-06&to=2015-09-06" }

      before do
        Time.zone = "UTC"
        Delorean.time_travel_to Date.iso8601("2015-12-07")

        # XXX: mock for Distributor#converted?
        allow_any_instance_of(Distributor).to receive(:transactional_customer_count).and_return(10)

        1.upto(12) do |i|
          date = "2015-%02d-01" % i
          sign_in_count = i%3 * 8
          # last_seen_at = sign_in_count.zero? ? nil : Date.iso8601(date) + 1.day

          Fabricate(:distributor,
            created_at: date,
            # last_seen_at: last_seen_at,
            sign_in_count: sign_in_count,
          )
        end

        # converted_distributor_ids = Distributor.all.select(&:converted?)

        # Fabricate.times(2, :distributor, created_at: "2015-01-01", last_seen_at: "2015-01-01", sign_in_count: 3)
      end

      it_behaves_like "an unauthenticated API", :get

      it "returns some JSON" do
        puts "today=#{Date.current}"
        puts "range=#{url.sub(/\A.*\?/, '')}"
        puts

        attrs = [:id, :created_at, :sign_in_count, :age_in_days, :sign_in_count_per_week, :converted?]
        p attrs

        Distributor.all.map do |d|
          values = attrs.map { |m| v = d.send(m); v.respond_to?(:to_date) ? v.to_date.iso8601 : v }
          values.map { |v|
            i = v.is_a?(String) ? 12 : 6
            print "%#{i}s" % v
          }
          puts
        end

        json_request :get, url, nil, headers

        expect(response).to be_success

        object_response = OpenStruct.new(json_response)

        # expect(
        #   [:over_6_months, :over_3_months, :over_1_month, :over_1_week].map do |key|
        #     object_response.public_send(key)
        #   end.sum
        # ).to eq 3

        expect(json_response).to eq ({
          converted: 1,
          over_6_months: 1,
          over_3_months: 1,
          over_1_month: 0,
          over_1_week: 0,
          logged_in: 2,
          not_logged_in: 1,
        }.with_indifferent_access)
      end
    end
  end
end
