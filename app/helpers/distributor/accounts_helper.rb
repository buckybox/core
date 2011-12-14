module Distributor::AccountsHelper
  def tag_links(tags)
    unless tags.empty?
      content_tag :ul, nil, :class => 'account_tags' do
        tags.reduce('') do |c, t|
          c << content_tag(:li, link_to(t.name, tag_distributor_accounts_path(current_distributor, t.name)))
        end.html_safe
      end
    end
  end
end
