class Distributor::ReportsController < ApplicationController

  def transaction_history
    date_from = Date.parse(params[:start])
    date_to = Date.parse(params[:to])

    csv_output = current_distributor.transaction_history_report(date_from, date_to)

    filename = "bucky-box-transaction-history-export-#{date_from.to_s(:transaction)}-to-#{date_to.to_s(:transaction)}.csv"
    type     = 'text/csv; charset=utf-8; header=present'

    send_data(csv_output, type: type, filename: filename)
  end

  def export_customer_account_history
    date = Date.parse(params[:to])
    csv_string = CustomerAccountHistoryCsv.generate(date, current_distributor)

    usercycle.event(current_distributor, "distributor_exported_csv_customer_account_history_list")

    send_csv("bucky-box-customer-account-balance-export-#{date.iso8601}", csv_string)
  end

end
