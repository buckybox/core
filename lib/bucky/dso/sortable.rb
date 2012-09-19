module Bucky::Dso
  class Sortable
    attr_accessor :sortable, :position

    def initialize(sortable, position)
      self.sortable = sortable
      self.position = position
    end

    def to_a
      [sortable, position]
    end
  end
end
