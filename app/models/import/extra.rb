# Find extra from import script, if given a box, limit it
# to the boxes allowed extras

class Import::Extra

  attr_reader :distributor, :extra, :box

  def initialize(args)
    @distributor = args.fetch(:distributor)
    @extra       = args.fetch(:extra)
    @box         = args.fetch(:box, nil)
  end

  def find
    search_extras = []
    box = find_box
    search_extras = get_extras(box)
    matches = get_matches(search_extras)
    get_match(matches)
  end

private

  def get_match(matches)
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

  def get_matches(search_extras)
    search_extras.select{|current_extra| current_extra.match_import_extra?(extra)}.
      collect{|extra_match| [extra_match.fuzzy_match(extra),extra_match]}.
      select{|fuzzy_match| fuzzy_match.first > Extra::FUZZY_MATCH_THRESHOLD}. # Set a lower threshold which weeds out almost matches and force the data to be fixed.  Make the user go fix the csv file.
      sort{|a,b| b.first <=> a.first}
  end

  def get_extras(box)
    if box.blank?
      distributor.extras.alphabetically
    elsif box.extras_allowed?
      box.extras.alphabetically
    else
      []
    end
  end

  def find_box
    box.present? ? distributor.find_box_from_import(box) : nil
  end

end
