require 'spec_helper'

include Bucky::Dso

describe Bucky::Dso::List do
  describe 'List#sort' do
    context :list do
      let(:list){ List.new([[:a, 1], [:b, 2], [:c, 3], [:d, 4]]) }

      it 'should make a new list' do
        list.to_a.should eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4]])
      end

      it 'should return DsoSortables in order' do
        nxt = list.next
        nxt.class.should eq(Sortable)
        nxt.to_a.should eq([:a, 1])
        list.next.to_a.should eq([:b, 2])
      end

      it 'should return nil when at end of list' do
        4.times{list.next}
        list.next.should eq(nil)
      end

      it 'should reset pointer' do
        5.times{list.next}
        list.reset
        list.next.to_a.should eq([:a, 1])
      end

      it 'should show next but not increment pointer' do
        list.peek.to_a.should eq([:a, 1])
        list.next.to_a.should eq([:a, 1])
        list.peek.to_a.should eq([:b, 2])
        list.next.to_a.should eq([:b, 2])
      end

      it 'should subtract elements from another list' do
        (list - List.ordered_list([:b, :a])).to_a.should eq([[:c, 3], [:d, 4]])
      end

      it 'should return true for empty list' do
        List.new.empty?.should be_true
      end

      it 'should return false for full list' do
        list.empty?.should be_false
      end

      it 'should return false when not pointing at last element' do
        list.finished?.should be_false
      end

      it 'should return true when pointing at last element' do
        4.times{list.next}
        list.finished?.should be_true
      end

      it 'should return all sortables' do
        list.sortables.should eq([:a, :b, :c, :d])
      end
      
      it 'should return all unique sortables from two lists' do
        list.merged_uniques(List.ordered_list([:b, :d, :e, :f, :z])).should eq([:a, :b, :c, :d, :e, :f, :z])
      end

      it 'should return the element before the one supplied' do
        list.before(:c).should eq(:b)
      end

      it 'should handle element not found' do
        list.before(:z).to_a.should eq([])
      end
    end

    context "#new" do
      it 'should accept a list without numbering and add it starting at 1' do
        List.new([:a, :b, :c, :d, :e, :f]).to_a.should eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6]])
      end
    end

    context "#ordered_list" do
      it 'should give temporary positions offset by 0.5' do
        List.ordered_list([:a, :b, :c, :d]).to_a.should eq([[:a, 1.5], [:b, 2.5], [:c, 3.5], [:d, 4.5]])
      end
    end

    context :sort do
      it "should sort the ordering into the master list" do
        master_list = List.new([[:a, 1], [:d, 2], [:c, 3], [:b, 4]])
        ordered_list = List.ordered_list([:b, :c, :d])

        List.sort(master_list, ordered_list).to_a.should eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4]])
      end

      it "should sort a different ordering into the master list" do
        master_list = List.new([[:e, 1], [:f, 2], [:h, 3], [:g, 4]])
        ordered_list = List.ordered_list([:e, :h, :g])

        List.sort(master_list, ordered_list).to_a.should eq([[:e, 1], [:f, 2], [:h, 3], [:g, 4]])
      end

      it "should sort a complex case" do
        master_list = List.new([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:f, 5], [:e, 6], [:h, 7], [:g, 8], [:i, 9], [:j, 10], [:k, 11]])
        ordered_list = List.ordered_list([:d, :e, :f, :g, :j, :k])

        List.sort(master_list, ordered_list).to_a.should eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6], [:g, 7], [:j, 8], [:k, 9], [:h, 10], [:i, 11]])
      end

      it "should sort a complex case" do
        master = [:a, :b, :c, :d, :f, :e, :h, :g, :i, :j, :k]
        ordered = [:d, :e, :f, :g, :j, :k]

        List.sort(master, ordered).to_a.should eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6], [:g, 7], [:j, 8], [:k, 9], [:h, 10], [:i, 11]])
      end

    end
  end
end
