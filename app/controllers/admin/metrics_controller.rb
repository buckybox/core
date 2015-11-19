class Admin::MetricsController < Admin::BaseController
  layout false

  def conversion_pipeline
  end

  caches_action :transactional_customers, expires_in: 1.week
  def transactional_customers
    today = Date.current
    data = []
    previous_cumulative_count = 0
    period = 52 + 52/2 # go back 18 months

    period.times do |week|
      date = today - week.weeks

      cumulative_count = Bucky::Sql.transactional_customer_count(nil, date)
      current_count = cumulative_count - previous_cumulative_count
      previous_cumulative_count = cumulative_count

      data_struct = OpenStruct.new(date: date.iso8601, count: current_count)

      data << data_struct
    end

    data.reverse!

    render locals: { data: data }
  end
end
