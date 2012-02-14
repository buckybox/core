SimpleForm::FormBuilder.class_eval do
  alias :old_button :button

  def button(type, *args, &block)
    options = args.extract_options!
    options[:class] = "button radius #{options[:class]}".strip

    args << options

    if respond_to?("#{type}_button")
      send("#{type}_button", *args, &block)
    else
      send(type, *args, &block)
    end
  end
end
