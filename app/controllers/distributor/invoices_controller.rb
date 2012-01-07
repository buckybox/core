class Distributor::InvoicesController < Distributor::BaseController
  belongs_to :distributor

  actions :index

  def to_send
    @invoices = Account.need_invoicing.collect {|a| Invoice.for_account(a) }
  end

  def do_send
    invoices = Invoice.generate_invoices
    if invoices.size > 0
      flash[:notice] = "Invoices successfully creataed"
    else
      flash[:error] = "No invoices created"
    end
    redirect_to :action => :index
  end
end
