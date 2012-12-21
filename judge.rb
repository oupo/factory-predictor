# coding: utf-8
require "set"
require "pp"
require_relative "prng.rb"
require_relative "rough-predictor.rb"

NUM_ENTRIES = 30
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 7

N = NUM_BATTLES
M = NUM_PARTY

# TODO 実際にありえるパスかどうかを判定する必要がある
def main
  starters = (0...NUM_STARTERS).to_a
  prng = PRNG.new(0)
  p prng
  x = RoughPredictor.predict(prng, starters)
  print_condition(x.to_a.sample, starters)
end

def print_condition(result, starters)
  shop, gate = result_to_shopgate(result, starters)
  (0..N - 2).each do |i|
    puts "shop #{i}: #{shop[i]}"
    puts "gate #{i+2}: #{gate[i+2]} : #{shop[i+2]}"
  end
  req = requests_list()
  pp req
  assign_top_priority_requests(req)
end

# gate iの一つ手前でアイテムaを得て少なくともgate jまで保持し続けるという仕事を
# Work.new(a, i, j)で表す
Work = Struct.new(:item, :head, :tail)
Work.class_eval do
  def range() head..tail end
end

# 絶対に採用する必要があるworkを採用する
def assign_top_priority_requests(req)
  assigner = Assigner.new()
  req.each do |r|
    if r.size == 1
      assigner.assign(r[0])
      puts "assigned: #{r[0]}"
    end
  end
end

# 仕事の割り当て
class Assigner
  def initialize
    @assigned = []
  end
  
  def assign(work)
    return if exist_similar_longer_work(work)
    assigned = pick_similar_work(work)
    if assignable0(assigned, work)
      @assigned = assigned + [work]
    else
      raise "impossible"
    end
  end
  
  def assignable?(work)
    return true if exist_similar_longer_work(work)
    assigned = pick_similar_work(work)
    assignable0(assigned, work)
  end

  private
  def assignable0(assigned, work)
    work.range.all? {|i| covered_num(assigned, i) < M } \
     and startable_num(assigned, work.head) >= 1
  end

  def exist_similar_longer_work(work)
    i = find_similar_work(work)
    i and work.tail <= @assigned[i].tail
  end

  def find_similar_work(work)
    @assigned.find_index {|w| [w.item, w.head] == [work.item, work.head] }
  end

  def pick_similar_work(work)
    i = find_similar_work(work)
    i ? @assigned.dup.tap {|x| x.delete_at(i) } : @assigned
  end

  def startable_num(assigned, pos)
    max = pos == 2 ? M : 1
    max - assigned.count {|work| work.head == pos }
  end

  def covered_num(assigned, pos)
    assigned.count {|work| work.range.include?(pos) }
  end
end


# 要求されるworkのリスト
def requests_list
  req = []
  (2..N).each do |i|
    @gate[i].each do |item|
      r = []
      (0..i-2).each do |j|
        if @shop[j].include?(item)
          r << Work.new(item, j + 2, i)
        end
      end
      req << r
    end
  end
  req
end

class Item
  def initialize(name)
    @name = name
  end

  def inspect
    @name
  end
end

def result_to_shopgate(result, starters)
  shop = []
  gate = []
  shop[0] = starters
  (1..N).each do |i|
    shop[i] = result.enemies[i-1]
  end
  (2..N).each do |i|
    gate[i] = result.skipped[i-1]
  end
  @shop, @gate = subst_item_id(shop, gate)
end

# デバッグのために、どこのshopで手に入れることができるかを表した名前にする
def subst_item_id(shop, gate)
  ref = {}
  (0..N).each do |i|
    shop[i].each do |item|
      ref[item] ||= []
      ref[item] << i if i <= N - 2
    end
  end
  used = ref.values.each_with_object(Hash.new(0)) {|r, u| u[r] += 1 }
  count = Hash.new(0)
  name = {}
  ref.each do |item, r|
    n = r.join("")
    if used[r] > 1 or n == ""
      n += "_" + ("a".ord + count[r]).chr
    end
    name[item] = Item.new(n)
    count[r] += 1
  end
  shop.each {|x| x.map!{|item| name[item] } }
  gate.each {|x| x and x.map!{|item| name[item] } }
  [shop, gate]
end


main() if $0 == __FILE__
