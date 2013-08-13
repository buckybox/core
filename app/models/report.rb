require 'date'
require 'csv'

module Report
  def self.format_date(date)
    date.iso8601
  end
end
