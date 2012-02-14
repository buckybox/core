class FileInput < SimpleForm::Inputs::FileInput
   def input
     "<div class=\"file-input\">
       <span class=\"radius small button\">#{input_html_options[:value] || "Browse..."}</span>
       <span class=\"description\"></span>
     </div>#{super}".html_safe
   end
end
