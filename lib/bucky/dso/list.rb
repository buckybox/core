module Bucky::Dso
  class List
    attr_accessor :list, :pointer

    def initialize(list=[])
      self.pointer = 0
      if list.first.is_a?(Array) || list.blank?
        self.list = list.collect{|sortable, position| Sortable.new(sortable, position)}
      else
        self.list = list.each_with_index.collect{|sortable, position| Sortable.new(sortable, position + 1)}
      end
    end

    def to_a
      list.collect(&:to_a)
    end

    def next
      n = peek
      self.pointer += 1
      return n
    end

    def reset
      self.pointer = 0
    end

    def peek
      list[pointer]
    end

    def empty?
      list.empty?
    end

    def finished?
      empty? || pointer == list.size
    end

    def -(list)
      hash = list.sortables.inject({}){|hash, key| hash.merge(key => true)}
      List.new(to_a.reject{|s| hash.key?(s.first)})
    end

    def before(sortable)
      if sortables.first == sortable || !sortables.include?(sortable)
        nil
      else
        s = list[sortables.index(sortable) - 1]
        s.blank? ? nil : s.sortable
      end
    end

    def match_before(sortable, possible_next)
      match = possible_next.blank? ? nil : before(possible_next.sortable)

      return !match.blank? && match == sortable
    end

    def sortables
      list.collect(&:sortable)
    end

    def self.ordered_list(list)
      List.new(list.each_with_index.collect{|i, index| [i, index+1.5]})
    end

    def self.merge(master, ordered)
      master_list = master.is_a?(List) ? master : List.new(master)
      ordered_list = ordered.is_a?(List) ? ordered : List.ordered_list(ordered)
      merge_list(master_list, ordered_list)
    end

    def self.merge_list(master_list, ordered_list)
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

    def merged_uniques(list)
      (self.sortables + list.sortables).uniq
    end
  end
end
