class Distributor::AccountsController < Distributor::ResourceController
  respond_to :html, :xml, :json

  def change_balance
    @account = Account.find(params[:id])

    respond_to do |format|
      if create_transaction(@account, params)
        format.html { redirect_to [:distributor, @account.customer], notice: 'Account balance was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to [:distributor, @account.customer] }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  def transactions
    offset_size = 0
    limit = params[:limit].to_i
    limit ||= 6

    limit += 6 if params[:more].present?
    @account = current_distributor.accounts.find(params[:id])
    @transactions = account_transactions(@account, offset_size, limit)
    @show_more_link = @transactions.size != @account.transactions.count

    @transactions_sum = @account.calculate_balance(offset_size)

    render partial: 'distributor/transactions/index'   
  end

  private

  def create_transaction(account, params)
    opts = {}
    delta = EasyMoney.new(params[:delta])

    if delta.zero?
      flash[:error] = 'Change in balance must be a number and not zero.'
    else
      opts[:delta] = delta
    end

    if params[:note].present?
      opts[:description] = params[:note]
    end

    if params[:date].present?
      opts[:display_time] = Date.parse(params[:date]).to_time_in_current_zone
    end

    !delta.zero? && account.create_transaction(delta, opts)
  end
end
