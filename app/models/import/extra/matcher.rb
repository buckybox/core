class Import::Extra::Matcher

  def initialize(args)
    @extra   = args.fetch(:match)
    @extras  = args.fetch(:from)
    @matches = preprocess
  end

  def closest_match
    if same_two_matches
      matches.select(&same_fuzzy_match).map(&:last).sort_by(&name_and_unit).first
    elsif matches.first.present?
      matches.first.last
    end
  end

private

  attr_reader :extra, :extras, :matches

  def same_two_matches
    matches.size > 1 && matches[0].first == matches[1].first
  end

  def same_fuzzy_match
    Proc.new { |match| match.first == matches.first.first }
  end

  def name_and_unit
    Proc.new { |current_extra| "#{current_extra.name} #{current_extra.unit}" }
  end

  def preprocess
    results = extras.select(&first_filter)
    results = results.map(&fuzzy_match).select(&fuzzy_filter)
    results.sort { |a,b| b.first <=> a.first }
  end

  def first_filter
    Proc.new { |current_extra| current_extra.match_import_extra?(extra) }
  end

  def fuzzy_match
    Proc.new { |extra_match| [ extra_match.fuzzy_match(extra), extra_match ] }
  end

  def fuzzy_filter
    Proc.new { |fuzzy_match| fuzzy_match.first > Extra::FUZZY_MATCH_THRESHOLD }
  end

end
