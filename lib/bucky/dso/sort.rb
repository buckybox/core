module Bucky::Dso
  class Sort
    def self.sort(master, ordered)
      master_list = master.is_a?(List) ? master : List.new(master)
      ordered_list = ordered.is_a?(List) ? ordered : List.ordered_list(ordered)
      sort_list(master_list, ordered_list)
    end
  end
end
