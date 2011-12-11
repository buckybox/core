class CurrencyInput < SimpleForm::Inputs::NumericInput
  def input
    "<span>$</span>#{super}".html_safe
  end
end
