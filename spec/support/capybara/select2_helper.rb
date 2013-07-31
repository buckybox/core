module Select2Helper
  # @example
  #   select2 "Item", from: "select_id"
  #
  # @note Works with Select2 version 3.4.1.
  def select2(text, options)
    find("#s2id_#{options[:from]}").click
    all(".select2-result-label").detect { |result| result.text == text }.click
  end
end
