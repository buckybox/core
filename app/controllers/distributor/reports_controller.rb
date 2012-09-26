class Distributor::ReportsController < ApplicationController

  def transaction_history
    date_from = Date.parse(params[:start])
    date_to = Date.parse(params[:to])

    csv_output = current_distributor.transaction_history_report(date_from, date_to)

    filename = "bucky-box-transaction-history-export-#{date_from.to_s(:transaction)}-to-#{date_to.to_s(:transaction)}.csv"
    type     = 'text/csv; charset=utf-8; header=present'

    send_data(csv_output, type: type, filename: filename)
  end

end
