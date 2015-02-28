# Find extra from import script, if given a box, limit it
# to the boxes allowed extras

class Import::Extra

  def initialize(args)
    @distributor = args.fetch(:distributor)
    @extra       = args.fetch(:extra)
    @box         = args.fetch(:box, nil)
  end

  def find
    found_box = find_box
    extras    = get_extras(found_box)
    matcher   = Import::Extra::Matcher.new(match: extra, from: extras)
    matcher.closest_match
  end

private

  attr_reader :distributor, :extra, :box

  def get_extras(found_box)
    if found_box.blank?
      distributor.extras.alphabetically
    elsif found_box.extras_allowed?
      found_box.extras.alphabetically
    else
      []
    end
  end

  def find_box
    box.present? ? distributor.find_box_from_import(box) : nil
  end

end
