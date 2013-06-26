class Distributor::AccountsController < Distributor::ResourceController
  respond_to :html, :xml, :json

  def change_balance
    @account = Account.find(params[:id])

    delta_cents = (BigDecimal.new(params[:delta]) * BigDecimal.new(100)).to_i

    if delta_cents != 0
      new_balance = @account.balance + Money.new(delta_cents)
      note = params[:note]

      if note.blank?
        @account.change_balance_to(new_balance, display_time: params[:date])
      else
        @account.change_balance_to(new_balance, description:note, display_time: params[:date])
      end
    else
      flash[:error] = 'Change in balance must be a number and not zero.'
    end

    respond_to do |format|
      if @account.save && delta_cents != 0
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
end
