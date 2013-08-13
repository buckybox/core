class Distributor::ReportsController < Distributor::BaseController

  def index
  end

  def transaction_history
    report = Report::TransactionHistory.new(distributor: current_distributor, from: params[:start], to: params[:to])
    tracking.event(current_distributor, "exported_transaction_history")
    send_csv(report.name, report.data)
  end

  def export_customer_account_history
    report = Report::CustomerAccountHistory.new(distributor: current_distributor, date: params[:to])
    tracking.event(current_distributor, "exported_customer_account_history")
    send_csv(report.name, report.data)
  end

end
