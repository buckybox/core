require 'spec_helper'

describe Metrics do
  describe ".calculate_and_store_for_munin" do
    let(:keys) { %w(
      new_distributors_last_7_days
      new_customers_last_7_days
      delivered_deliveries_last_day
    ) }

    it "dumps the metrics" do
      Metrics.calculate_and_store_for_munin

      raw_metrics_config = File.read(Metrics::MUNIN_METRICS_CONFIG_FILE)
      raw_metrics_config.should include(*keys)

      raw_metrics_regexp = keys.map do |key|
        "#{key}.value \\d+"
      end.join("\n")

      raw_metrics = File.read(Metrics::MUNIN_METRICS_FILE)
      raw_metrics.should match raw_metrics_regexp
    end
  end
end

