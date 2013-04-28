require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

class Judge
  def initialize(env, result)
    @env = env
    @shop = (0..nBattles).map {|i|
      if i == 0
        result.starters.map(&:item)
      else
        result.enemies[i-1].map(&:item)
      end
    }
    @gate = (0..nBattles).map {|i|
      if i >= 2
        result.skipped[i-1].map(&:item)
      end
    }
  end

  attr_reader :env
  include EnvMixin 
  include FactoryHelper

  def self.judge(env, result)
    new(env, result).judge()
  end

  def judge
    schedule = assign_works()
    schedule != nil and judge0(schedule)
  end
  
  def assign_works
    assigner = Assigner.new(@env)
    (2..nBattles).each do |i|
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
    (2..nBattles).each do |i|
      # gate iの手前のshop
      sh = @shop[i-2]
      if i == 2
        items = schedule.select{|w| w.head == i }.map(&:item)
        player = items
        player += (sh - items).sort_by{|item| -caught(item, i) }.take(nParty - items.size)
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
    (pos..nBattles).find{|i| @shop[i].include?(item) } || nBattles+1
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
  def initialize(env)
    @env = env
    @assigned = []
  end

  attr_reader :env
  include EnvMixin 

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

  private
  def assignable0(assigned, work)
    work.range.all? {|i| covered_num(assigned, i) < nParty }\
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
    max = pos == 2 ? nParty : 1
    max - assigned.count {|work| work.head == pos }
  end

  def covered_num(assigned, pos)
    assigned.count {|work| work.range.include?(pos) }
  end
end

if $0 == __FILE__
  require_relative "rough.rb"
  require_relative "naive.rb"
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 7, all_entries_file: "entries.csv")
  10.times do |i|
    seed = i
    prng = PRNG.new(seed)
    result = RoughPredictor.predict(env, prng)
    result_filtered = result.select{|x| Judge.judge(env, x) }.map(&:enemies).to_set
    puts "#{result_filtered.size} / #{result.size}"
    #naive_result = NaivePredictor.predict(env, prng)
    #p result_filtered == naive_result
  end
end
