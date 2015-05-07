require 'spec_helper'

include Bucky::Dso

describe Bucky::Dso::List do
  let(:list) { List.new([[:a, 1], [:b, 2], [:c, 3], [:d, 4]]) }

  it 'should make a new list' do
    expect(list.to_a).to eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4]])
  end

  it 'should return DsoSortables in order' do
    nxt = list.next
    expect(nxt.class).to eq(Sortable)
    expect(nxt.to_a).to eq([:a, 1])
    expect(list.next.to_a).to eq([:b, 2])
  end

  it 'should return nil when at end of list' do
    4.times { list.next }
    expect(list.next).to eq(nil)
  end

  it 'should reset pointer' do
    5.times { list.next }
    list.reset
    expect(list.next.to_a).to eq([:a, 1])
  end

  it 'should show next but not increment pointer' do
    expect(list.peek.to_a).to eq([:a, 1])
    expect(list.next.to_a).to eq([:a, 1])
    expect(list.peek.to_a).to eq([:b, 2])
    expect(list.next.to_a).to eq([:b, 2])
  end

  it 'should subtract elements from another list' do
    expect((list - List.ordered_list([:b, :a])).to_a).to eq([[:c, 3], [:d, 4]])
  end

  it 'should return true for empty list' do
    expect(List.new.empty?).to be true
  end

  it 'should return false for full list' do
    expect(list.empty?).to be false
  end

  it 'should return false when not pointing at last element' do
    expect(list.finished?).to be false
  end

  it 'should return true when pointing at last element' do
    4.times { list.next }
    expect(list.finished?).to be true
  end

  it 'should return all sortables' do
    expect(list.sortables).to eq([:a, :b, :c, :d])
  end

  it 'should return all unique sortables from two lists' do
    expect(list.merged_uniques(List.ordered_list([:b, :d, :e, :f, :z]))).to eq([:a, :b, :c, :d, :e, :f, :z])
  end

  it 'should return the element before the one supplied' do
    expect(list.before(:c)).to eq(:b)
  end

  it 'should handle element not found' do
    expect(list.before(:z).to_a).to eq([])
  end

  it 'should accept a list without numbering and add it starting at 1' do
    expect(List.new([:a, :b, :c, :d, :e, :f]).to_a).to eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6]])
  end

  describe ".ordered_list" do
    it 'should give temporary positions offset by 0.5' do
      expect(List.ordered_list([:a, :b, :c, :d]).to_a).to eq([[:a, 1.5], [:b, 2.5], [:c, 3.5], [:d, 4.5]])
    end
  end

  describe ".sort" do
    it "should sort the ordering into the master list" do
      master_list = List.new([[:a, 1], [:d, 2], [:c, 3], [:b, 4]])
      ordered_list = List.ordered_list([:b, :c, :d])

      expect(List.sort(master_list, ordered_list).to_a).to eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4]])
    end

    it "should sort a different ordering into the master list" do
      master_list = List.new([[:e, 1], [:f, 2], [:h, 3], [:g, 4]])
      ordered_list = List.ordered_list([:e, :h, :g])

      expect(List.sort(master_list, ordered_list).to_a).to eq([[:e, 1], [:f, 2], [:h, 3], [:g, 4]])
    end

    it "should sort a complex case" do
      master_list = List.new([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:f, 5], [:e, 6], [:h, 7], [:g, 8], [:i, 9], [:j, 10], [:k, 11]])
      ordered_list = List.ordered_list([:d, :e, :f, :g, :j, :k])

      expect(List.sort(master_list, ordered_list).to_a).to eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6], [:h, 7], [:g, 8], [:i, 9], [:j, 10], [:k, 11]])
    end

    it "should sort a complex case" do
      master = [:a, :b, :c, :d, :f, :e, :h, :g, :i, :j, :k]
      ordered = [:d, :e, :f, :g, :j, :k]

      expect(List.sort(master, ordered).to_a).to eq([[:a, 1], [:b, 2], [:c, 3], [:d, 4], [:e, 5], [:f, 6], [:h, 7], [:g, 8], [:i, 9], [:j, 10], [:k, 11]])
    end
  end
end
