# coding: utf-8
require "set"
require "pp"
require_relative "prng.rb"
require_relative "rough-predictor.rb"
require_relative "judge-context.rb"

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
  results = RoughPredictor.predict(prng, starters).to_a
  results_filtered = results.select{|r| judge(r, starters) }
  print_context results_filtered.last, starters
end

def print_context(result, starters)
  context = JudgeContext.from_predictor_result(result, starters)
  shop, gate = context.shop, context.gate
  (0..N - 2).each do |i|
    puts "shop #{i}: #{shop[i]}"
    puts "gate #{i+2}: #{gate[i+2]} : #{shop[i+2]}"
  end
  pp context.requests
end

def judge(result, starters)
  context = JudgeContext.from_predictor_result(result, starters)
  assign_loop(context)
end

# gate iの一つ手前でアイテムaを得て少なくともgate jまで保持し続けるという仕事を
# Work.new(a, i, j)で表す
Work = Struct.new(:item, :head, :tail)
Work.class_eval do
  def range() head..tail end
end

# 絶対に採用する必要があるworkを採用することを続ける
def assign_loop(context)
  assigner = Assigner.new(context.shop)
  requests = context.requests.to_a
  begin
    updated = false
    requests.each_with_index do |req, i|
      next if req == nil
      c = req.count {|r| assigner.assignable?(r) }
      return false if c == 0
      if c == 1
        assigner.assign(req.find {|r| assigner.assignable?(r) })
        requests[i] = nil
        updated = true
      end
    end
  end while updated
  true
end

# 仕事の割り当て
class Assigner
  def initialize(bad)
    @assigned = []
    @bad = bad
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
    work.range.all? {|i| covered_num(assigned, i) < M }\
      and startable_num(assigned, work.head) >= 1 \
      and pass_bad_condition(work)
  end

  def pass_bad_condition(work)
    work.range.all? {|i| not @bad[i].include?(work.item) }
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

main() if $0 == __FILE__
