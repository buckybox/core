class FileInput < SimpleForm::Inputs::FileInput
  def input
    button_text = input_html_options[:value] || input_html_options[:label] || 'Browse...'

    "<div class='file-input'>
      <span class='btn'>#{button_text}</span>
      <span class='description'></span>
    </div>#{super}".html_safe
  end
end
