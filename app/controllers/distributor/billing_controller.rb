class Distributor::BillingController < Distributor::BaseController
  before_action :fetch_pricing

  def show
    last_invoices = current_distributor.invoices.where("created_at >= ?", Date.iso8601("2020-06-01")).order('distributor_invoices.to').last(5).reverse
    render locals: {
      invoices: last_invoices,
      current_pricing: @current_pricing,
      next_pricing: @next_pricing,
      other_pricings: @other_pricings,
      bank_account: @bank_account,
    }
  end

  def invoice
    invoice = current_distributor.invoices.find_by!(number: params[:number])

    render locals: {
      reference: invoice.reference,
      recipient: invoice.distributor.localised_address.postal_address_with_recipient,
      created_at: invoice.created_at.to_date,
      due_at: (invoice.created_at + 15.days).to_date,
      from: invoice.from,
      to: invoice.to,
      description: invoice.description,
      amount: invoice.amount.with_currency(invoice.currency),
      currency: invoice.currency,
      paid: invoice.paid,
      bank_account: @bank_account,
    }
  end

private

  def fetch_pricing
    @current_pricing = current_distributor.pricing
    @next_pricing = Distributor::Pricing.where(distributor_id: current_distributor.id).last
    @other_pricings = @current_pricing.pricings_for_currency.reject do |pricing|
      (@next_pricing && @next_pricing == pricing) || (!@next_pricing && @current_pricing == pricing)
    end

    @bank_account = \
      case @current_pricing.currency
      when 'NZD'
        nil
      when 'AUD'
        SimpleForm::BankAccountNumber::Formatter.formatted_bank_account_number(Figaro.env.transferwise_bank_account_au, 'AU').to_s
      when 'EUR'
        SimpleForm::BankAccountNumber::Formatter.formatted_bank_account_number(Figaro.env.transferwise_bank_account_be, 'BE').to_s
      when 'GBP'
        SimpleForm::BankAccountNumber::Formatter.formatted_bank_account_number(Figaro.env.transferwise_bank_account_gb, 'GB').to_s
      else
        SimpleForm::BankAccountNumber::Formatter.formatted_bank_account_number(Figaro.env.transferwise_bank_account_nz, 'NZ').to_s
      end
    end
end
