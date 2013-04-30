require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

class Judge
  def initialize(env, result)
    @env = env
    @shop = (0..nBattles).map {|i|
      if i == 0
        result.starters
      else
        result.enemies[i-1]
      end
    }
    @gate = (0..nBattles).map {|i|
      if i >= 2
        result.skipped[i-1]
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
    assigner, req = assign_loop()
    return false if assigner == nil
    req_comb(assigner, req).any? {|schedule| judge0(schedule) }
  end
  
  def list_requests
    req = []
    (2..nBattles).each do |i|
      @gate[i].each do |req_entry|
        r = []
        (0..i-2).reverse_each do |j|
          @shop[j].each do |entry|
            if entry.collides_with?(req_entry) and r.none?{|w| w.entry == entry }
              r << Work.new(entry, j + 2, i)
            end
          end
        end
        req << r
      end
    end
    req
  end

  def req_comb(assigner, req)
    if req == []
      return [assigner.assigned]
    end
    req[0].product(*req[1..-1]).map {|works|
      a = assigner.dup
      if a.assign_works(works)
        a.assigned
      end
    }.compact
  end

  def assign_loop
    assigner = Assigner.new(@env)
    req = list_requests()
    begin
      updated = false
      req.size.times do |i|
        next if req[i] == nil
        req[i] = req[i].select {|r| assigner.assignable?(r) }
        return nil if req[i].length == 0
        if req[i].length == 1
          assigner.assign(req[i].first)
          req[i] = nil
          updated = true
        end
      end
    end while updated
    [assigner, req.compact]
  end

  def judge0(schedule)
    player = nil
    (2..nBattles).each do |i|
      # gate iの手前のshop
      if i == 2
        player = greedy_select_starters(schedule, i)
      else
        player = greedy_exchange(schedule, i, player)
      end

      # gate i
      return false if player.any?{|e| e.collides_within?(@shop[i]) }
    end
    true
  end

  def greedy_select_starters(schedule, i)
    sh = @shop[i-2]
    entries = schedule.select{|w| w.head == i }.map(&:entry)
    player = entries
    player += (sh - entries).sort_by{|entry| -caught(entry, i) }.take(nParty - entries.size)
    player
  end

  def greedy_exchange(schedule, i, player)
    sh = @shop[i-2]
    current_works = schedule.select{|w| w.range.include?(i) and w.head != i }
    player_desertable = player - current_works.map(&:entry)
    a = player_desertable.min_by{|entry| caught(entry, i) }
    work = schedule.find{|w| w.head == i }
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
    (pos..nBattles).find{|i| entry.collides_within?(@shop[i]) } || nBattles+1
  end
end


if $0 == __FILE__
  require_relative "trial-rough.rb"
  require_relative "naive.rb"
  all_entries = FactoryHelper.gen_all_entries(150, 150, 50)
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 4, all_entries: all_entries)
  20.times do |seed|
    print "seed = %#.8x: " % seed
    prng = PRNG.new(seed)
    result = RoughPredictor.predict(env, prng)
    result_filtered = result.select{|x| Judge.judge(env, x) }
    naive_result = NaivePredictor.predict(env, prng)
    puts "#{naive_result.size} ; #{result_filtered.size} / #{result.size}"
  end
end
