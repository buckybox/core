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
      @orders = @account.orders.completed.active
      @deliveries = @account.deliveries
      @transactions = @account.transactions
      @customer = @account.customer
      @address = @customer.address
    end
  end

  def change_balance
    @account = Account.find(params[:id])

    delta_cents = params[:delta].to_i

    if delta_cents != 0
      new_balance = @account.balance + Money.new(delta_cents * 100)
      note = params[:note]

      if note.blank?
        @account.change_balance_to(new_balance)
      else
        @account.change_balance_to(new_balance, description:note)
      end
    else
      flash[:error] = 'Change in balance must be a number and not zero.'
    end

    respond_to do |format|
      if @account.save && delta_cents != 0
        format.html { redirect_to [current_distributor, @account], notice: 'Account balance was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
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
