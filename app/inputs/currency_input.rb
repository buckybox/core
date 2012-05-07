class CurrencyInput < SimpleForm::Inputs::NumericInput
  def input
    currency_symbol = "<span>#{Money.default_currency.symbol}</span>"

    if Money.default_currency.symbol_first
      currency_symbol = "#{currency_symbol}#{super}"
    else
      currency_symbol = "#{super}#{currency_symbol}"
    end

    return currency_symbol.html_safe
  end
end
