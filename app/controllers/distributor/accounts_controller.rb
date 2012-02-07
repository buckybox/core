class Distributor::AccountsController < Distributor::BaseController
  belongs_to :distributor

  respond_to :html, :xml, :json

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
        format.html { redirect_to [current_distributor, @account.customer], notice: 'Account balance was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end
end
