# coding: utf-8
require "set"
require "pp"

NUM_ENTRIES = 30
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 4

N = NUM_BATTLES
M = NUM_PARTY

require_relative "prng.rb"
require_relative "rough-predictor.rb"
require_relative "judge-context.rb"
require_relative "naive.rb"

def main
  starters = (0...NUM_STARTERS).to_a
  100.times do |i|
    prng = PRNG.new(i)
    x = predict_fast(prng, starters)
    y = predict_naive(prng, starters)
    puts "#{i}: #{x.size} #{y.size}"
    if x != y
      puts "in fast, but not in naive: #{(x - y).inspect}"
      puts "in naive, but not in fast: #{(y - x).inspect}"
      puts "common: #{(x & y).inspect}"
      exit
    end
  end
end

def predict_fast(prng, starters)
  RoughPredictor.predict(prng, starters).select{|x| judge(x, starters) }.map(&:enemies).to_set
end

def predict_naive(prng, starters)
  NaivePredictor.predict(prng, starters)
end

def print_context(result, starters)
  context = JudgeContext.from_predictor_result(result, starters)
  shop, gate = context.shop, context.gate
  (0..N - 2).each do |i|
    puts "shop #{i}: #{shop[i]}"
    puts "gate #{i+2}: #{gate[i+2]} : #{shop[i+2]}"
  end
  pp context.requests
  succeeded, requests, assigner = assign_loop(context)
  pp assigner.assigned
end

def judge(result, starters)
  context = JudgeContext.from_predictor_result(result, starters)
  succeeded, requests, assigner = assign_loop(context)
  succeeded and judge0(context, assigner)
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
  req = context.requests.dup
  begin
    updated = false
    req.size.times do |i|
      next if req[i] == nil
      req[i] = req[i].select {|r| assigner.assignable?(r) }
      return false if req[i].length == 0
      if req[i].length == 1
        assigner.assign(req[i].first)
        req[i] = nil
        updated = true
      end
    end
  end while updated
  p req.compact if req.compact.size > 0
  [true, req.compact, assigner]
end

def judge0(context, assigner)
  shop = context.shop
  assigned = assigner.assigned
  player = nil
  (2..N).each do |i|
    # gate iの手前のshop
    sh = shop[i-2]
    if i == 2
      items = assigned.select{|w| w.head == i }.map(&:item)
      player = items
      player += (sh - items).sort_by{|item| -caught(context, item, i) }.take(M - items.size)
    else
      doing_work = assigned.select{|w| w.range.include?(i) and w.head != i }
      player_desertable = player - doing_work.map(&:item)
      a = player_desertable.min_by{|item| caught(context, item, i) }
      work = assigned.find{|w| w.head == i }
      if work
        player = (player - [a]) + [work.item]
      else
        b = sh.max_by{|item| caught(context, item, i) }
        if caught(context, a, i) < caught(context, b, i)
          player = (player - [a]) + [b]
        end
      end
    end

    # gate i
    return false if not (player & shop[i]).empty?
  end
  true
end

def caught(context, item, pos)
  (pos..N).find{|i| context.shop[i].include?(item) } || N+1
end

# 仕事の割り当て
class Assigner
  def initialize(bad)
    @assigned = []
    @bad = bad
  end

  attr_reader :assigned
  
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

  def startable_num(pos)
    startable_num0(@assigned, pos)
  end

  def covered_num(pos)
    covered_num0(@assigned, pos)
  end

  private
  def assignable0(assigned, work)
    work.range.all? {|i| covered_num0(assigned, i) < M }\
      and startable_num0(assigned, work.head) >= 1 \
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

  def startable_num0(assigned, pos)
    max = pos == 2 ? M : 1
    max - assigned.count {|work| work.head == pos }
  end

  def covered_num0(assigned, pos)
    assigned.count {|work| work.range.include?(pos) }
  end
end

main() if $0 == __FILE__
