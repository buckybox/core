class Distributor::AccountsController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

  def index
    index! do
      @accounts.sort! { |a,b| a.customer.name <=> b.customer.name }
    end
  end

  def show
    show! do
      @orders = @account.orders
      @transactions = @account.transactions
      @customer = @account.customer
      @address = @customer.address
    end
  end

  def update
    update! do |success, failure|
      delta_cents = params[:account][:delta].to_i * 100

      if delta_cents != 0
        new_balance = @account.balance + Money.new(delta_cents)
        @account.change_balance_to(new_balance)
        @account.save
      end

      success.html { redirect_to [current_distributor, @account] }
      failure.html { render action: 'edit' }
    end
  end

  protected

  def collection
    @accounts = end_of_association_chain.includes(:customer => :address)

    @accounts = @accounts.tagged_with(params[:tag]) unless params[:tag].blank?

    unless params[:query].blank?
      customers = @distributor.customers.search(params[:query])
      @accounts = @accounts.where(:customer_id => customers.map(&:id))
    end

    @accounts = @accounts.page(params[:page]) if params[:page]
  end
end
