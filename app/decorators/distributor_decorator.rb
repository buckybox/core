class DistributorDecorator < Draper::Decorator
  delegate_all

  def banks
    object.banks.to_sentence({two_words_connector: " or ", last_word_connector: ", or "}).html_safe
  end
end
