# Not the best way to do this, particularly if an upgrade to the gem breaks this.
# Better solution will be to build a form helper that sits on top of simple_form
# Read discussion here: https://github.com/plataformatec/simple_form/pull/657

module SimpleForm
  module ActionViewExtensions
    # This module creates SimpleForm wrappers around default form_for and fields_for.
    #
    # Example:
    #
    #   simple_form_for @user do |f|
    #     f.input :name, :hint => 'My hint'
    #   end
    #
    module FormHelper
      # Override the default ActiveRecordHelper behaviour of wrapping the input.
      # This gets taken care of semantically by adding an error class to the wrapper tag
      # containing the input.
      #
      FIELD_ERROR_PROC = proc do |html_tag, instance_tag|
        html_tag
      end

      def simple_form_for(record, options={}, &block)
        options[:builder] ||= SimpleForm::FormBuilder
        options[:html] ||= {}
        unless options[:html].key?(:novalidate)
          options[:html][:novalidate] = !SimpleForm.browser_validations
        end
        if options[:html].key?(:only_class)
          options[:html][:class] = options[:html].delete(:only_class)
          class_array = []
        else
          class_array = [SimpleForm.form_class]
        end
        class_array << simple_form_css_class(record, options)
        options[:html][:class] = class_array.compact.join(" ")

        with_simple_form_field_error_proc do
          form_for(record, options, &block)
        end
      end
    end
  end
end
