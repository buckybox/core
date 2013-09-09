class Distributor::BankInformationController < Distributor::BaseController
  before_filter :fetch_payment_settings

  def update
    type = params[:type] || "bank_deposit"

    if params[:bank_deposit]
      params[:bank_deposit][:account_number] = params[:bank_deposit][:account_number].join
    end

    if @payment_settings.save
      tracking.event(current_distributor, "new_bank_information") unless current_admin.present?
      redirect_to distributor_settings_payments_url(type: type), notice: "Your #{@payment_method} settings were successfully updated."

    else
      flash[:error] = "You must fill in all the required fields."
      render 'distributor/settings/payments', locals: {
        bank_deposit:     bank_deposit,
        cash_on_delivery: cash_on_delivery,
        type:             type
      }
    end
  end

private

  def fetch_payment_settings
    %w(bank_deposit cash_on_delivery).each do |payment_method|
      if params[payment_method]
        @payment_method = payment_method.titleize
        @payment_settings = send(payment_method)
      end
    end
  end

  def bank_deposit
    Distributor::Settings::Payments::BankDeposit.new(params_with_distributor)
  end

  def cash_on_delivery
    Distributor::Settings::Payments::CashOnDelivery.new(params_with_distributor)
  end

  def params_with_distributor
    params.merge(distributor: current_distributor)
  end
end
