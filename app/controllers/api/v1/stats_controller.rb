class Api::V1::StatsController < Api::V1::BaseController
  skip_before_action :authenticate, only: :conversion_pipeline

  def conversion_pipeline
    Time.zone = "UTC"

    six_months_ago = 6.months.ago
    three_months_ago = 3.months.ago
    one_month_ago = 1.month.ago
    one_week_ago = 1.week.ago

    from = DateTime.parse(params.fetch("from", three_months_ago).to_s)
    to = DateTime.parse(params.fetch("to", Time.zone.now + 1.day).to_s)

    distributors = Distributor.where("created_at BETWEEN ? AND ?", from, to)
    converted_distributor_ids = distributors.where("last_seen_at > ?", one_month_ago).select { |d| d.transactional_customer_count > 9 }.map(&:id)
    converted_distributor_clause = converted_distributor_ids.empty? ? "1=0" : "id IN (#{converted_distributor_ids.join(',')})"
    converted_distributors = distributors.where(converted_distributor_clause)
    not_converted_distributors = distributors.where("NOT(#{converted_distributor_clause})")

    stats = {
      converted: converted_distributors.count,
      over_6_months: not_converted_distributors.where("last_seen_at < ?", six_months_ago).count,
      over_3_months: not_converted_distributors.where("last_seen_at BETWEEN ? AND ?", six_months_ago, three_months_ago).count,
      over_1_month: not_converted_distributors.where("last_seen_at BETWEEN ? AND ?", three_months_ago, one_month_ago).count,
      over_1_week: not_converted_distributors.where("last_seen_at BETWEEN ? AND ?", one_month_ago, one_week_ago).count,
      logged_in: not_converted_distributors.where("last_seen_at > ?", one_week_ago).count,
      not_logged_in: not_converted_distributors.where("last_seen_at IS NULL").count,
      total: distributors.count,
    }

    raise if distributors.count * 2 != stats.values.sum

    render json: stats
  end
end
