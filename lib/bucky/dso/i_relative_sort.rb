module Bucky::Dso
  class IRelativeSort < RelativeSort
    
    def self.sort_list(master_list, ordered_list)
      working_list = IRelativeList.build(master_list)
      
      ordered_list.each_with_index do |sortable, o_index|
        w_index = working_list.index(sortable)

        test_index = lowest_index(working_list, ordered_list[(o_index+1)..-1])
        working_list.move(w_index, test_index) if !test_index.nil? && w_index > test_index
      end
      working_list.update_positions
      working_list
    end

    def self.lowest_index(working_list, ordered_list)
      min = working_list.index(ordered_list.first)
      ordered_list.each do |s|
        i = working_list.index(s)
        min = i if i < min
      end
      min
    end

  end
end
