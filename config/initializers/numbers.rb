class Fixnum
  alias_method :old_ordinalize, :ordinalize

  # @param options Option hash
  #   :long boolean Long format ("first", "second", "third", ...)
  def ordinalize(options = {})
    options = { long: false }.merge options

    if options[:long]
      words = ['zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth', 'ninth', 'tenth', 'eleventh', 'twelth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth']
      deca_prefixes = {20 => 'twenty', 30 => 'thirty', 40 => 'forty', 50 => 'fifty', 60 => 'sixty', 70 => 'seventy', 80 => 'eighty', 90 => 'ninety'}
      return words[self] unless self >= words.size
      suffix = self % 10
      prefix = self - suffix
      return deca_prefixes[prefix].chop.concat('ieth') if suffix == 0
      return deca_prefixes[prefix] + '-' + words[suffix]
    else
      self.old_ordinalize
    end
  end
end
