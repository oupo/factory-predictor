require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

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
    prng, starters = choose_entries(prng, nStarters)
    predict0(prng, [], starters)
  end

  def predict0(prng, enemies, starters)
    if enemies.length == nBattles
      return [enemies].to_set
    end
    unchoosable = enemies.last || starters
    maybe_players = starters + enemies[0..-2].flatten
    results = OneEnemyPredictor.predict(env, prng, unchoosable, maybe_players)
    results.map {|result|
      predict0(result.prng, enemies + [result.chosen], starters)
    }.inject(:+)
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

  Result = Struct.new(:prng, :chosen)

  def predict0(prng, skipped, chosen)
    if chosen.length == nParty
      return [Result.new(prng, chosen)].to_set
    end
    prngp, x = choose_entry(prng)
    if x.collides_within?(@unchoosable + chosen + skipped)
      predict0(prngp, skipped, chosen)
    elsif not x.collides_within?(@maybe_players) or skipped.length == nParty
      predict0(prngp, skipped, chosen + [x])
    else
      result1 = predict0(prngp, skipped, chosen + [x])
      result2 = predict0(prngp, skipped + [x], chosen)
      result1 + result2
    end
  end
end

if $0 == __FILE__
  require_relative "naive.rb"
  env = Env.new(nParty: 3, nStarters: 6, nBattles: 4)

  10.times do
    seed = rand(2**32)
    print "%.8x: " % seed
    prng = PRNG.new(seed)
    result1 = RoughPredictor.predict(env, prng)
    print "#{result1.size} results"
    result2 = NaivePredictor.predict(env, prng)
    print " / #{result2.size} results."
    puts " / #{result2.subset?(result1)}"
  end
end
