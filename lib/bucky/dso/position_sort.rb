module Bucky::Dso
  class PositionSort < Sort
    
    def self.sort_list(master_list, ordered_list)
      last_insert = nil
      
      absent_list = master_list - ordered_list
      new_master_list = []
      
      until absent_list.finished? && ordered_list.finished?
        if !absent_list.finished? && (ordered_list.finished? || (master_list.match_before(last_insert, absent_list.peek) || absent_list.peek.position < ordered_list.peek.position))
          insert = absent_list.next.to_a
          last_insert = insert.blank? ? nil : insert.first
        else
          insert = ordered_list.next.to_a
          last_insert = nil
        end
        new_master_list << insert
      end

      List.new(new_master_list.each_with_index.collect{|s, index| [s.first, index+1]})
    end

  end
end
