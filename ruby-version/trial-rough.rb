require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"
require_relative "trial-scheduler.rb"

# 1つの敵のエントリーの決定範囲には同じ種族が複数存在しないという前提を外した試作バージョン

def main
  all_entries = FactoryHelper.gen_all_entries(50, 20, 20)
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 3, all_entries: all_entries)

  unchoosable = []
  maybe_players = env.all_entries
  result1 = OneEnemyPredictor.predict(env, PRNG.new(0), unchoosable, maybe_players)
  puts "#{result1.size} results."
  result2 = NaiveOneEnemyPredictor.predict(env, PRNG.new(0), unchoosable, maybe_players)
  puts "#{result2.size} results."
  p result2.subset?(result1)
end

def main
  require_relative "naive.rb"
  all_entries = FactoryHelper.gen_all_entries(150, 150, 50)
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 4, all_entries: all_entries)
  20.times do |i|
    seed = i
    result = RoughPredictor.predict(env, PRNG.new(seed))
    naive_result = NaivePredictor.predict(env, PRNG.new(seed))
    puts "#{result.size}, #{naive_result.size} (#{naive_result.subset?(result)})"
  end
end

def measure
  start = Time.now
  x = yield
  time = Time.now - start
  [x, time]
end

class RoughPredictor
  def initialize(env)
    @env = env
  end

  attr_reader :env
  include EnvMixin 
  include FactoryHelper

  def self.predict(env, prng)
    new(env).predict(prng)
  end

  def predict(prng)
    prng, starters = choose_entries(@env, prng, nStarters)
    scheduler = Scheduler.new(@env, starters)
    predict0(prng, [], [], scheduler, starters)
  end

  Result = Struct.new(:prng, :enemies, :skipped, :starters)

  def predict0(prng, enemies, skipped, scheduler, starters)
    if enemies.length == nBattles
      return [enemies].to_set
      #return [Result.new(prng, enemies, skipped, starters)].to_set
    end
    unchoosable = enemies.last || starters
    maybe_players = starters + enemies[0..-2].flatten
    results = OneEnemyPredictor.predict(env, prng, unchoosable, maybe_players)

    results.map {|r|
      schedulerp = scheduler.add(r.chosen, r.skipped)
      if schedulerp
        predict0(r.prng, enemies + [r.chosen], skipped + [r.skipped], schedulerp, starters)
      end
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

  def self.predict(env, prng, unchoosable, maybe_players)
    new(env, unchoosable, maybe_players).predict(prng)
  end

  def predict(prng)
    predict0(prng, [], [])
  end

  Result = Struct.new(:prng, :chosen, :skipped)

  def predict0(prng, skipped, chosen)
    if chosen.length == nParty
      return [Result.new(prng, chosen, skipped)].to_set
    end
    if not coverable?(skipped)
      return [].to_set
    end
    prngp, x = choose_entry(@env, prng)
    if x.collides_within?(@unchoosable + chosen) or skipped.include?(x)
      predict0(prngp, skipped, chosen)
    elsif not x.collides_within?(@maybe_players)
      predict0(prngp, skipped, chosen + [x])
    else
      result1 = predict0(prngp, skipped, chosen + [x])
      result2 = predict0(prngp, skipped + [x], chosen)
      result1 + result2
    end
  end

  # タグを6つ適当に選べばentriesをカバーできるかを判定する
  def coverable?(entries)
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
