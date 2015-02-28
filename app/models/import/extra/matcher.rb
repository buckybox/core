class Import::Extra::Matcher

  def initialize(args)
    @extra   = args.fetch(:match)
    @extras  = args.fetch(:from)
    @matches = preprocess
  end

  def closest_match
    if matches.size > 1 && matches.first.first == matches[1].first
      # At-least the first two matches have the same fuzzy_match (probably no unit set)
      # So return the first one alphabetically so that it is consistent
      matches.select{ |m| m.first == matches.first.first }. #Select those which have the same fuzzy_match
        collect(&:last). # discard the fuzzy_match number
        sort_by{|current_extra| "#{current_extra.name} #{current_extra.unit}"}.first # Sort alphabeticaly
    else
      matches.first.last if matches.first.present?
    end
  end

private

  attr_reader :extra, :extras, :matches

  def preprocess
    extras.select{|current_extra| current_extra.match_import_extra?(extra)}.
      collect{|extra_match| [extra_match.fuzzy_match(extra),extra_match]}.
      select{|fuzzy_match| fuzzy_match.first > Extra::FUZZY_MATCH_THRESHOLD}. # Set a lower threshold which weeds out almost matches and force the data to be fixed.  Make the user go fix the csv file.
      sort{|a,b| b.first <=> a.first}
  end

end
