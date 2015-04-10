require 'spec_helper'

describe Metrics do
  describe ".calculate_and_store_for_munin" do
    let(:keys) do %w(
      new_distributors_last_7_days
      new_transactional_customers_last_7_days
    ) end

    it "dumps the metrics" do
      Metrics.calculate_and_store_for_munin

      raw_metrics_config = File.read(Metrics::MUNIN_WEEKLY_METRICS_CONFIG_FILE)
      expect(raw_metrics_config).to include(*keys)

      raw_metrics_regexp = keys.map do |key|
        "#{key}.value \\d+"
      end.join("\n")

      raw_metrics = File.read(Metrics::MUNIN_WEEKLY_METRICS_FILE)
      expect(raw_metrics).to match raw_metrics_regexp
    end
  end
end

