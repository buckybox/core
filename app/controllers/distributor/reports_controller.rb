class Distributor::ReportsController < ApplicationController

  def transaction_history
    date_from = Date.parse(params[:start])
    date_to = Date.parse(params[:to])

    csv_string = current_distributor.transaction_history_report(date_from, date_to)
    filename = "bucky-box-transaction-history-export-#{date_from.to_s(:transaction)}-to-#{date_to.to_s(:transaction)}"

    tracking.event(current_distributor, "exported_transaction_history")

    send_csv(filename, csv_string)
  end

  def export_customer_account_history
    date = Date.parse(params[:to])
    csv_string = CustomerAccountHistoryCsv.generate(date, current_distributor)

    tracking.event(current_distributor, "exported_customer_account_history")

    send_csv("bucky-box-customer-account-balance-export-#{date.iso8601}", csv_string)
  end

end
