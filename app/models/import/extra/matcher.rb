class Import::Extra::Matcher

  def initialize(args)
    @extra   = args.fetch(:match)
    @matches = args.fetch(:from)
  end

  def closest_match
    if same_two_matches
      matches.select(&same_fuzzy_match).map(&:last).sort_by(&name_and_unit).first
    elsif first_match.present?
      first_match.last
    end
  end

private

  attr_reader :extra, :matches

  def same_two_matches
    matches.size > 1 && first_match.first == second_match.first
  end

  def same_fuzzy_match
    Proc.new { |match| match.first == first_match.first }
  end

  def name_and_unit
    Proc.new { |current_extra| "#{current_extra.name} #{current_extra.unit}" }
  end

  def first_match
    @first_match ||= matches.to_a[0]
  end

  def second_match
    @second_match ||= matches.to_a[0]
  end

end
