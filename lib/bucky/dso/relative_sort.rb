module Bucky::Dso
  class RelativeSort < Sort

    def self.sort_list(master_list, ordered_list)
      working_list = RelativeList.build(master_list)
      
      ordered_list.each_with_index do |sortable, o_index|
        w_index = working_list.index(sortable)

        test_index = lowest_index(working_list, ordered_list[(o_index+1)..-1])
        working_list.move(w_index, test_index) if !test_index.nil? && w_index > test_index

        w_index = working_list.index(sortable)
        test_index = highest_index(working_list, ordered_list[0..o_index])
        working_list.move(w_index, test_index) if w_index < test_index
      end
      working_list
    end

    def self.lowest_index(working_list, ordered_list)
      ordered_list.collect{|s| working_list.index(s)}.min
    end
    
    def self.highest_index(working_list, ordered_list)
      ordered_list.collect{|s| working_list.index(s)}.max
    end

  end
end
