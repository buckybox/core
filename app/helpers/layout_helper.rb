module LayoutHelper
  FLASH_CLASSES = {
    notice:   'alert-success',
    warning:  'info-warning',
    error:    'alert-error',
    alert:    'alert-error',
    info:     'alert-info',
  }.freeze

  def title(page_title, show_title = true)
    content_for(:title) { h(page_title.to_s) }
    @show_title = show_title
  end

  def show_title?
    @show_title
  end

  def stylesheet(*args)
    content_for(:head) { stylesheet_link_tag(*args) }
  end

  def javascript(*args)
    content_for(:head) { javascript_include_tag(*args) }
  end

  def render_site_messages(flash, options = {})
    unless flash.empty?
      content = flash.map { |kind, message| flash_bar(message, kind: kind) }
      content = content.join.html_safe

      unless options[:container] == false
        content = content_tag(:div, content_tag(:div, content, class: 'span12'), class: 'row-fluid')
      end
    end

    content
  end

  def flash_bar(message, options = {})
    classes = 'alert'
    classes += " #{FLASH_CLASSES.fetch(options[:kind].to_sym)}" if options[:kind]

    message = button_tag('&times;'.html_safe, type: 'button', class: 'close', data: { dismiss: 'alert' }) + message if options.fetch(:close, true)

    content_tag(:div, message.html_safe, class: classes)
  end

  def checkmark_boolean(value)
    (value ? '&#x2714' : '&#10007').html_safe
  end

  def customer_title(customer, options = {})
    html_tag = options.delete(:html_tag) || :h1

    html_options = { class: '', id: '' }
    html_options[:class] += 'text-center' if options.delete(:center)
    html_options[:class] += options.delete(:class).to_s
    html_options[:id] = options.delete(:id) if options[:id]

    title_text = options.delete(:title) || customer_and_number(customer)
    title(title_text, false)

    content_tag(html_tag, customer_badge(customer, options), html_options)
  end

  def customer_and_number(customer)
    "##{customer.formated_number} #{customer.name}"
  end

  def customer_badge(customer, options = {})
    cache_key = [
      :customer_badge,
      customer.id,
      customer.updated_at,
      options.hash,
    ].join("/")

    Rails.cache.fetch(cache_key) do
      customer_id = customer.formated_number.to_s

      content = \
        case options[:link]
        when false
          content_tag(:span, customer_id, class: 'customer-id')
        when Hash
          link_to(customer_id, url_for(options[:link]), class: 'customer-id')
        when String
          link_to(customer_id, options[:link], class: 'customer-id')
        else
          link_to(customer_id, [:distributor, customer], class: 'customer-id')
        end

      customer_name = options[:customer_name] || customer.name
      customer_name = truncate(customer_name, length: 18) if options[:short]
      content += content_tag(:span, customer_name,
        class: 'customer-name', title: customer_name,
        'data-customer-id' => customer.id,
        'data-customer-email' => customer.email
      )

      badge = content_tag(:span, content.html_safe, class: 'customer-badge')

      [options[:before], badge, options[:after]].join.html_safe
    end
  end

  def customer_tags(customer)
    cache_key = [
      :customer_tags,
      customer.id,
      customer.updated_at,
    ].join("/")

    Rails.cache.fetch(cache_key) do
      content = ""
      customer = customer.decorate unless customer.decorated?

      customer.dynamic_tags.each do |tag, label|
        content << link_to(content_tag(:span, tag, class: "label label-status label-#{label}"), tag_distributor_customers_path(tag), class: 'link-label') << " "
      end

      tags = customer.tags.sort_by { |tag| tag.name.length }
      tags_html = tags.map do |tag|
        link_to(content_tag(:span, tag.name, class: 'label label-info'), tag_distributor_customers_path(tag.name), class: 'link-label') << " "
      end.join.html_safe

      content << content_tag(:span, tags_html, class: 'tag-links', data: { "toggle" => "tooltip", "placement" => "left", "title" => tags.join(' ') })

      content.html_safe
    end
  end

  def intro_tour(show_tour)
    if controller_path =~ /^distributor/
      if controller_name == 'customers' && action_name == 'show'
        tour_type = 'customers_show'
      elsif controller_name == 'customers' && action_name == 'index'
        tour_type = 'customers_index'
      elsif controller_name == 'deliveries' && action_name == 'index'
        tour_type = if params[:view] == 'packing'
          'deliveries_index_packing'
        else
          'deliveries_index_deliveries'
        end
      elsif controller_name == 'payments' && action_name == 'index'
        tour_type = 'payments_index'
      end

      if tour_type
        locals = { show_tour: show_tour, tour_type: tour_type }
        render partial: 'distributor/shared/intro_tour', object: "intro_tour/#{tour_type}.png", locals: locals
      end
    end
  end
end
