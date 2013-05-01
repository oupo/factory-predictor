require_relative "factory-helper.rb"

class Scheduler
  def initialize(env, starters)
    @env = env
    @shop = []
    @gate = []
    @req = []
    @assigner = Assigner.new(env)
    @shop[0] = starters
    @pos = 0
  end

  attr_reader :env
  include EnvMixin
  include FactoryHelper

  def add(enemy, skipped)
    s = dup()
    s.add!(enemy, skipped) ? s : nil
  end

  def all_schedule_comb
    if @req == []
      return [@assigner.assigned]
    end
    @req[0].product(*@req[1..-1]).map {|works|
      a = @assigner.dup
      if a.assign_works(works)
        a.assigned
      end
    }.compact
  end

  alias orig_dup dup
  def dup
    orig_dup().instance_eval {
      @shop = @shop.dup
      @gate = @gate.dup
      @req = @req.dup
      @assigner = @assigner.dup
      self
    }
  end

  def add!(enemy, skipped)
    @pos += 1
    @shop[@pos] = enemy
    @gate[@pos] = skipped
    add_req @pos
    if not assign_loop()
      Stats.add @pos, :fail_schedule
      false
    elsif all_schedule_comb().none?{|schedule| Judge.judge(@env, @shop, @pos, schedule) }
      Stats.add @pos, :fail_judge
      false
    else
      Stats.add @pos, :pass
      true
    end
  end

  def add_req(i)
    @gate[i].each do |req_entry|
      r = []
      (0..i-2).reverse_each do |j|
        @shop[j].each do |entry|
          if entry.collides_with?(req_entry) and r.none?{|w| w.entry == entry }
            r << Work.new(entry, j + 2, i)
          end
        end
      end
      @req << r
    end
  end

  def assign_loop
    begin
      updated = false
      @req.size.times do |i|
        next if @req[i] == nil
        @req[i] = @req[i].select {|r| @assigner.assignable?(r) }
        return false if @req[i].length == 0
        if @req[i].length == 1
          @assigner.assign(@req[i].first)
          @req[i] = nil
          updated = true
        end
      end
    end while updated
    @req.compact!
    true
  end
end

class Judge
  def initialize(env, shop, len, schedule)
    @env = env
    @shop = shop
    @len = len
    @schedule = schedule
  end

  attr_reader :env
  include EnvMixin
  include FactoryHelper

  def self.judge(env, shop, len, schedule)
    new(env, shop, len, schedule).judge()
  end

  def judge
    player = nil
    (2..@len).each do |i|
      # gate iの手前のshop
      if i == 2
        player = greedy_select_starters(i)
      else
        player = greedy_exchange(i, player)
      end

      # gate i
      return false if player.any?{|e| e.collides_within?(@shop[i]) }
    end
    true
  end

  def greedy_select_starters(i)
    sh = @shop[i-2]
    entries = @schedule.select{|w| w.head == i }.map(&:entry)
    player = entries
    player += (sh - entries).sort_by{|entry| -caught(entry, i) }.take(nParty - entries.size)
    player
  end

  def greedy_exchange(i, player)
    sh = @shop[i-2]
    current_works = @schedule.select{|w| w.range.include?(i) and w.head != i }
    player_desertable = player - current_works.map(&:entry)
    a = player_desertable.min_by{|entry| caught(entry, i) }
    work = @schedule.find{|w| w.head == i }
    if work
      (player - [a]) + [work.entry]
    elsif player_desertable == []
      player
    else
      b = sh.max_by{|entry| caught(entry, i) }
      if caught(a, i) < caught(b, i)
        (player - [a]) + [b]
      else
        player
      end
    end
  end

  def caught(entry, pos)
    (pos..@len).find{|i| entry.collides_within?(@shop[i]) } || @len+1
  end
end

# gate iの一つ手前でエントリーaを得て少なくともgate jまで保持し続けるという仕事を
# Work.new(a, i, j)で表す
Work = Struct.new(:entry, :head, :tail)
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

  def assign_works(works)
    works.each do |work|
      return false if not assignable?(work)
      assign work
    end
    true
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
    @assigned.find_index {|w| [w.entry, w.head] == [work.entry, work.head] }
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
