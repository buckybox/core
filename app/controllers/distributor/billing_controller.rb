class Distributor::BillingController < Distributor::BaseController
  def show
    last_invoices = current_distributor.invoices.where("created_at >= ?", Date.iso8601("2020-06-01")).order('distributor_invoices.to').last(5).reverse
    current_pricing = current_distributor.pricing
    next_pricing = Distributor::Pricing.where(distributor_id: current_distributor.id).last
    other_pricings = current_pricing.pricings_for_currency.reject do |pricing|
      (next_pricing && next_pricing == pricing) || (!next_pricing && current_pricing == pricing)
    end

    bank_account = \
      case current_pricing.currency
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

    render locals: {
      current_pricing: current_pricing,
      next_pricing: next_pricing,
      other_pricings: other_pricings,
      invoices: last_invoices,
      bank_account: bank_account,
    }
  end
end
