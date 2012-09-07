module Bucky::Dso
  class RelativeList < List
    
    def self.build(list=[])
      if list.is_a?(List)
        RelativeList.new(list.to_a)
      else
        RelativeList.new(list)
      end
    end

    def is_in_place?(sortable, above, below)
      is_above?(sortable, below) && is_below?(sortable, above)
    end

    def is_above?(sortable, below)
      return true if below.nil?
      index(sortable) > index(below)
    end

    def is_below?(sortable, above)
      return true if above.nil?
      index(sortable) < index(below)
    end
  end
end
