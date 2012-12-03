class Customer::AccountsController < Customer::ResourceController

  def transactions
    offset_size = 0
    limit = params[:limit].to_i
    limit ||= 6
    
    limit += 6 if params[:more].present?
    
    @distributor = current_customer.distributor
    if current_customer.account.id == params[:account_id].to_i
      @account = current_customer.account
    end
    @transactions = account_transactions(@account, offset_size, limit)
    @show_more_link = @transactions.size != @account.transactions.count

    @transactions_sum = @account.calculate_balance(offset_size)
    @balance = current_customer.account.balance

    render partial: 'customer/transactions/index'
  end

end
