require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"
require_relative "trial-scheduler.rb"
require_relative "naive.rb"

# 1つの敵のエントリーの決定範囲には同じ種族が複数存在しないという前提を外した試作バージョン

# ナイーブ版と結果比較
def main_naive_cmp
  all_entries = FactoryHelper.gen_all_entries(150, 150, 50)
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 5, all_entries: all_entries)
  20.times do |i|
    seed = i
    result = RoughPredictor.predict(env, PRNG.new(seed)).map(&:enemies).to_set
    naive_result = NaivePredictor.predict(env, PRNG.new(seed))
    puts "#{seed}: #{naive_result.size} #{result.size} (#{naive_result == result})"
  end
end

def main
  all_entries = FactoryHelper.gen_all_entries(150, 150, 50)
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 7, all_entries: all_entries)
  srand 0
  seed = 0
  time, result = measure {
    RoughPredictor.predict(env, PRNG.new(seed)).to_a
  }
  i = rand(result.size)
  puts "result[#{i}]"
  r = result[i]
  puts "startes: #{r.starters}"
  env.nBattles.times do |i|
    puts "#{i+1}: #{r.enemies[i]} #{r.skipped[i]}"
  end
  (1..env.nBattles).each do |i|
    stats = [:pass, :fail_schedule, :fail_judge].map{|n| Stats.stats[[i,n]] || 0 }
    puts "#{i}: #{stats.join(" ")}"
  end
  puts "time: #{time}"
  p Profiler.result
end

def measure
  start = Time.now
  x = yield
  time = Time.now - start
  [time, x]
end

module Stats
  module_function
  def add(level, status)
    @stats ||= Hash.new
    @stats[[level, status]] ||= 0
    @stats[[level, status]] += 1
  end

  def stats
    @stats ||= Hash.new
  end
end

module Profiler
  module_function
  def start(mode)
    @time = Hash.new(0.0)
    @count = Hash.new(0)
    @last_mode = mode
    @last_time = Time.now
  end

  def mode(mode)
    time = Time.now
    @time[@last_mode] += time - @last_time
    @count[@last_mode] += 1
    @last_mode = mode
    @last_time = time
  end

  def end()
    mode nil
  end

  def result
    [@time, @count]
  end
end

class RoughPredictor
  def initialize(env)
    @env = env
  end

  attr_reader :env
  include EnvMixin
  include FactoryHelper

  def self.predict(env, prng)
    Profiler.start :other
    new(env).predict(prng)
  ensure
    Profiler.end
  end

  def predict(prng)
    prng, starters = choose_entries(@env, prng, nStarters)
    scheduler = Scheduler.new(@env, starters)
    predict0(prng, [], [], scheduler, starters)
  end

  Result = Struct.new(:prng, :enemies, :skipped, :starters)

  def predict0(prng, enemies, skipped, scheduler, starters)
    if enemies.length == nBattles
      #return [enemies].to_set
      return [Result.new(prng, enemies, skipped, starters)].to_set
    end
    unchoosable = enemies.last || starters
    maybe_players = starters + enemies[0..-2].flatten

    results = OneEnemyPredictor.predict(env, prng, unchoosable, maybe_players, scheduler)

    results.map {|r|
      predict0(r.prng, enemies + [r.chosen], skipped + [r.skipped], r.scheduler, starters)
    }.compact.inject(:+)
  end
end

class OneEnemyPredictor
  def initialize(env, unchoosable, maybe_players)
    @env = env
    @unchoosable = unchoosable
    @maybe_players = maybe_players
  end

  attr_reader :env
  include EnvMixin
  include FactoryHelper

  def self.predict(env, prng, unchoosable, maybe_players, scheduler)
    new(env, unchoosable, maybe_players).predict(prng, scheduler)
  end

  def predict(prng, scheduler)
    schedulerp = scheduler.new_enemy()
    predict0(prng, schedulerp, [], []).select{|r| r.scheduler != nil }
  end

  Result = Struct.new(:prng, :scheduler, :skipped, :chosen)

  def predict0(prng, scheduler, skipped, chosen)
    if chosen.length == nParty
      return [Result.new(prng, scheduler.end_enemy(chosen), skipped, chosen)].to_set
    end
    if scheduler == nil
      return [].to_set
    end
    prngp, x = choose_entry(@env, prng)
    if x.collides_within?(@unchoosable + chosen) or skipped.include?(x)
      predict0(prngp, scheduler, skipped, chosen)
    elsif not x.collides_within?(@maybe_players)
      predict0(prngp, scheduler, skipped, chosen + [x])
    else
      result1 = predict0(prngp, scheduler, skipped, chosen + [x])
      result2 = predict0(prngp, scheduler.add(x), skipped + [x], chosen)
      result1 + result2
    end
  end

  # タグを6つ適当に選べばentriesをカバーできるかを判定する
  def coverable?(entries)
    Profiler.mode :coverable?
    all_tags = entries.map(&:item).to_set + entries.map(&:pokemon).to_set
    selected_tags = Set.new
    covered = Set.new
    linked = Hash.new
    entries.each do |entry|
      (linked[entry.item] ||= Set.new).add entry
      (linked[entry.pokemon] ||= Set.new).add entry
    end

    # カバーできるエントリーの個数についての貪欲法でタグを6つ選ぶ
    (nParty*2).times do |i|
      tags = all_tags - selected_tags
      break if tags.empty?
      tag = tags.max_by {|tag|
        (linked[tag] - covered).size
      }
      selected_tags.add tag
      covered += linked[tag]
    end
    covered  == entries.to_set
  ensure
    Profiler.mode :other
  end
end

class NaiveOneEnemyPredictor
  def initialize(env, unchoosable, maybe_players)
    @env = env
    @unchoosable = unchoosable
    @maybe_players = maybe_players
  end

  attr_reader :env
  include EnvMixin
  include FactoryHelper

  def self.predict(env, prng, unchoosable, maybe_players)
    new(env, unchoosable, maybe_players).predict(prng)
  end

  def predict(prng)
    result = Set.new
    @maybe_players.combination(3) do |players|
      prngp, entries, skipped = choose_entries(@env, prng, nParty, players + @unchoosable)
      result.add OneEnemyPredictor::Result.new(prngp, entries, skipped)
    end
    result
  end
end

main() if $0 == __FILE__
