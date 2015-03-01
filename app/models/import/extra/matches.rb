class Import::Extra::Matches

  def self.by_fuzzy_match(args)
    matches = new(args)
    matches.by_fuzzy_match
  end

  def initialize(args)
    @distributor = args.fetch(:distributor)
    @extra       = args.fetch(:extra)
    @box         = args[:box]
  end

  def by_fuzzy_match
    extras.select(&with_import_filter)
      .map(&as_fuzzy_matches)
      .select(&with_fuzzy_filter)
      .sort(&by_score)
  end

  def extras
    if box.blank?
      distributor.extras.alphabetically
    elsif box.extras_allowed?
      box.extras.alphabetically
    else
      []
    end
  end

private

  attr_reader :distributor, :extra, :box

  def with_import_filter
    Proc.new { |current_extra| current_extra.match_import_extra?(extra) }
  end

  def as_fuzzy_matches
    Proc.new { |extra_match| [ extra_match.fuzzy_match(extra), extra_match ] }
  end

  def with_fuzzy_filter
    Proc.new { |fuzzy_match| fuzzy_match.first > Extra::FUZZY_MATCH_THRESHOLD }
  end

  def by_score
    Proc.new { |a, b| b.first <=> a.first }
  end

end
