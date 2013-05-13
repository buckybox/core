module HumanNumber
  module_function

  # Turn an integer into "first", "second", "third", ...
  # @param number Fixnum
  # @return String Ordinalised number
  def ordinalise number
    words = ['zeroth', 'first', 'second', 'third', 'fourth', 'fifth', 'sixth', 'seventh', 'eighth', 'ninth', 'tenth', 'eleventh', 'twelth', 'thirteenth', 'fourteenth', 'fifteenth', 'sixteenth', 'seventeenth', 'eighteenth', 'nineteenth']
    deca_prefixes = {20 => 'twenty', 30 => 'thirty', 40 => 'forty', 50 => 'fifty', 60 => 'sixty', 70 => 'seventy', 80 => 'eighty', 90 => 'ninety'}
    return words[number] unless number >= words.size
    suffix = number % 10
    prefix = number - suffix
    return deca_prefixes[prefix].chop.concat('ieth') if suffix == 0
    return deca_prefixes[prefix] + '-' + words[suffix]
  end
end
