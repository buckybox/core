class Distributor::Settings::Payments::PaypalController < Distributor::Settings::Payments::BaseController
  before_action do
    @paypal = Distributor::Settings::Payments::Paypal.new(
      params.merge(distributor: current_distributor)
    )
  end

  def show
    render_form
  end

  def update
    if @paypal.save
      track

      redirect_to distributor_settings_payments_paypal_path,
        notice: "Your PayPal settings were successfully updated."
    else
      flash.now[:error] = @paypal.errors.to_sentence

      render_form
    end
  end

private

  def render_form
    render 'distributor/settings/payments/paypal', locals: {
      paypal: @paypal,
    }
  end
end
