module Distributor::BaseHelper
  # force_highlighted = :delivery_services
  # will make the 'DeliveryServices' sub_nav title show as highlighted
  def show_settings_sub_nav(force_highlighted = nil)
    content_for :sub_nav do
      render partial: 'distributor/settings/sub_nav', locals: { force_highlighted: force_highlighted }
    end
  end

  def sub_tab(text, path, opts = {})
    highlighted = current_page?(path) ||
                  params[:controller].humanize.include?(text.downcase) ||
                  opts[:force_highlighted].to_s == text.downcase

    content_tag(:li, class: highlighted ? 'active' : '') do
      link_to text, path
    end
  end

  def distributor_nav_li(text, link, options = {})
    current_path = request.fullpath
    klass = 'active' if /^#{link}/ =~ current_path
    klass = 'active' if link == '/distributor/customers' && (current_path == '/' || current_path == '/distributor')

    list_item = content_tag(:div, nil, class: 'nav-arrow')

    list_item += content_tag :a, href: link, id: options.delete(:link_id) do
      content_tag(:div, nil, class: 'nav-image') +
        content_tag(:div, text, class: 'nav-text')
    end

    content_tag(:li, list_item, class: klass)
  end

  def link_to_submit(*args, &block)
    options = args.extract_options!.merge!(href: "javascript:void(0)")

    link_action = options["data-link-action"]

    function = ""
    function << "$('#link_action').val(\"#{link_action}\");" if link_action.present?
    function << "$(this).closest('form').submit()"

    name = block_given? ? capture(&block) : args[0]

    link_to_function name, function, options
  end
end
