# Find extra from import script, if given a box, limit it
# to the boxes allowed extras

class Import::Extra
  def initialize(args)
    @distributor = args.fetch(:distributor)
    @extra       = args.fetch(:extra)
    @box         = matched_box(args[:box])
  end

  def find
    matcher = Import::Extra::Matcher.new(match: extra, from: matches)
    matcher.closest_match
  end

private

  attr_reader :distributor, :extra, :box

  def matched_box(find_box)
    distributor.find_box_from_import(find_box) if find_box && find_box.present?
  end

  def matches
    Import::Extra::Matches.by_fuzzy_match(
      distributor: distributor,
      box: box,
      extra: extra
    )
  end
end
