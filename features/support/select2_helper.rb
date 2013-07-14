module Select2Helper
  # @example
  #   select2_select "Item", from: "select_id"
  #
  # @note Works with Select2 version 3.4.1.
  def select2_select(text, options)
    page.find("#s2id_#{options[:from]}").click
    page.all(".select2-result-label").detect { |result| result.text == text }.click
  end
end
 
World(Select2Helper)

