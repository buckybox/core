class Distributor::Settings::Payments::BankDepositController < Distributor::Settings::Payments::BaseController
  before_filter do
    @bank_deposit = Distributor::Settings::Payments::BankDeposit.new(
      params.merge(distributor: current_distributor)
    )
  end

  def show
    render_form
  end

  def update
    if @bank_deposit.save
      track

      redirect_to distributor_settings_payments_bank_deposit_path,
        notice: "Your Bank Deposit settings were successfully updated."
    else
      flash[:error] = "You must fill in all the required fields."

      render_form
    end
  end

private

  def render_form
    render 'distributor/settings/payments/bank_deposit', locals: {
      bank_deposit: @bank_deposit,
    }
  end
end
