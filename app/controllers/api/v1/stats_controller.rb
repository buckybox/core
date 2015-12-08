class Api::V1::StatsController < Api::V1::BaseController
  skip_before_action :authenticate, only: :conversion_pipeline

  def conversion_pipeline
    Time.zone = "UTC"

    six_months_ago = 6.months.ago
    three_months_ago = 3.months.ago
    one_month_ago = 1.month.ago
    one_week_ago = 1.week.ago

    from = DateTime.parse(params.fetch("from").to_s)
    to = DateTime.parse(params.fetch("to", Time.zone.now + 1.day).to_s)

    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    distributors = Distributor.where("created_at BETWEEN ? AND ?", from, to)
    # ActiveRecord::Base.logger = nil
    converted_distributor_ids = distributors.select(&:converted?).map(&:id)
    converted_distributor_clause = converted_distributor_ids.empty? ? "1=0" : "id IN (#{converted_distributor_ids.join(',')})"
    converted_distributors = distributors.where(converted_distributor_clause)
    not_converted_distributors = distributors.where("NOT(#{converted_distributor_clause})")

    stats = {
      converted: converted_distributors.count,
      over_6_months: distributors.where("last_seen_at < ?", six_months_ago).count,
      over_3_months: distributors.where("last_seen_at BETWEEN ? AND ?", six_months_ago, three_months_ago).count,
      over_1_month: distributors.where("last_seen_at BETWEEN ? AND ?", three_months_ago, one_month_ago).count,
      over_1_week: distributors.where("last_seen_at BETWEEN ? AND ?", one_month_ago, one_week_ago).count,
      logged_in: distributors.where("sign_in_count != 0").count,
      not_logged_in: distributors.where("sign_in_count = 0").count,
    }

    # raise if distributors.count * 2 != stats.values.sum

    render json: stats
  end

end
