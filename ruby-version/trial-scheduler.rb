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
    assign_loop
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
