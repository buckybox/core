class Distributor::Settings::Payments::CashOnDeliveryController < Distributor::Settings::Payments::BaseController
  before_filter do
    @cash_on_delivery = Distributor::Settings::Payments::CashOnDelivery.new(
      params.merge(distributor: current_distributor)
    )
  end

  def show
    render_form
  end

  def update
    if @cash_on_delivery.save
      track

      redirect_to distributor_settings_payments_cash_on_delivery_path,
        notice: "Your Cash on Delivery settings were successfully updated."
    else
      flash[:error] = "You must fill in all the required fields."

      render_form
    end
  end

private

  def render_form
    render 'distributor/settings/payments/cash_on_delivery', locals: {
      cash_on_delivery: @cash_on_delivery,
    }
  end
end

