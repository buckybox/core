class Distributor::AccountsController < Distributor::ResourceController
  respond_to :html, :xml, :json

  def change_balance
    @account = Account.find(params[:id])

    delta_cents = (params[:delta].to_f * 100.0).to_i

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
        format.html { render action: 'edit' }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end
end
