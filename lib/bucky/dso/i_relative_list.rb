module Bucky::Dso
  class IRelativeList < RelativeList

    def index(key)
      key = key.sortable if key.is_a?(Sortable)

      @index_lookup ||= {}

      if @index_lookup.key?(key)
        @index_lookup[key]
      else
        scan_indexes(key)
      end
    end

    def scan_indexes(key)
      i = 0
      @last_scan_index ||= i

      for i in @last_scan_index..(list.size-1)
        s = list[j]
        @index_lookup[s.sortable] = i
        break if s.sortable == key
      end
      @last_scan_index = i
      i
    end

    def move(from, to)
      @index_lookup = nil
      @last_scan_index = nil
      insert(to, delete_at(from))
    end

  end
end
