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
  Predictor.predict(prng, starters).map(&:enemies).to_set
end

def predict_naive(prng, starters)
  NaivePredictor.predict(prng, starters)
end

class Predictor
  def self.predict(prng, starters)
    new().predict(prng, starters)
  end

  def predict(prng, starters)
    RoughPredictor.predict(prng, starters).select{|x| Judge.judge(x, starters) }
  end
end

class Judge
  def initialize(result, starters)
    @shop = (0..N).map {|i|
      if i == 0
        starters.dup
      else
        result.enemies[i-1].dup
      end
    }
    @gate = (0..N).map {|i|
      if i >= 2
        result.skipped[i-1].dup
      end
    }
  end

  def self.judge(result, starters)
    new(result, starters).judge()
  end

  def judge
    schedule = assign_works()
    schedule and judge0(schedule)
  end
  
  def assign_works
    assigner = Assigner.new
    (2..N).each do |i|
      @gate[i].each do |item|
        j = (0..i-2).select {|j| @shop[j].include?(item) }.max
        return nil if j == nil
        work = Work.new(item, j + 2, i)
        return nil if not assigner.assignable?(work)
        assigner.assign work
      end
    end
    assigner.assigned
  end

  def judge0(schedule)
    player = nil
    (2..N).each do |i|
      # gate iの手前のshop
      sh = @shop[i-2]
      if i == 2
        items = schedule.select{|w| w.head == i }.map(&:item)
        player = items
        player += (sh - items).sort_by{|item| -caught(item, i) }.take(M - items.size)
      else
        current_works = schedule.select{|w| w.range.include?(i) and w.head != i }
        player_desertable = player - current_works.map(&:item)
        a = player_desertable.min_by{|item| caught(item, i) }
        work = schedule.find{|w| w.head == i }
        if work
          player = (player - [a]) + [work.item]
        else
          b = sh.max_by{|item| caught(item, i) }
          if caught(a, i) < caught(b, i)
            player = (player - [a]) + [b]
          end
        end
      end

      # gate i
      return false if not (player & @shop[i]).empty?
    end
    true
  end

  def caught(item, pos)
    (pos..N).find{|i| @shop[i].include?(item) } || N+1
  end
end

# gate iの一つ手前でアイテムaを得て少なくともgate jまで保持し続けるという仕事を
# Work.new(a, i, j)で表す
Work = Struct.new(:item, :head, :tail)
Work.class_eval do
  def range() head..tail end
end

# 仕事の割り当て
class Assigner
  def initialize
    @assigned = []
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
      and startable_num0(assigned, work.head) >= 1
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
