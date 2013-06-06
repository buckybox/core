module Select2Helper
  def select2_select(text, options)
    # FIXME snippet found on the interwebs, not sure if it works properly
    page.find("#s2id_#{options[:from]} input").click
    page.all("ul.select2-results li").each do |e|
      if e.text == text
        e.click
        return
      end
    end
  end
end

World(Select2Helper)

