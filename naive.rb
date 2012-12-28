require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

def Array.product(x, n)
  Array.each_product(x, n).to_a
end

def Array.each_product(x, n)
  return to_enum(__method__, x, n) if not block_given?
  (x.size ** n).times do |elem|
    yield (n-1).downto(0).map{|i| x[(elem / (x.size ** i)) % x.size] }
  end
end

class NaivePredictor
  def initialize(env)
    @env = env
  end

  attr_reader :env
  include EnvMixin 

  def predict(prng)
    starters = FactoryHelper.choose_entries(prng, nStarters)
    set = Set.new
    starters.combination(nParty).each do |player|
      each_exchanging do |exchanging|
        set.add choose_enemies(prng.dup, starters, player, exchanging)
      end
    end
    set
  end

  def each_exchanging
    exchanging_elems = [nil] + Array.product((0...nParty).to_a, 2)
    Array.each_product(exchanging_elems, nBattles - 2) do |exchanging|
      yield exchanging + [nil] # 最後の交換は影響しないから「なし」に固定していい
    end
  end

  def choose_enemies(prng, starters, player, exchanging)
    result = []
    unchoosable = starters
    nBattles.times do |i|
      enemy = FactoryHelper.choose_entries(prng, nParty, unchoosable)
      result.push enemy
      unchoosable = player + enemy
      player = exchange(player, enemy, exchanging[i])
    end
    result
  end
  
  def exchange(player, enemy, exchanging)
    if exchanging == nil
      player
    else
      (i, j) = exchanging
      player.dup.tap{|p| p[i] = enemy[j] }
    end
  end
end

env = Env.new(nParty: 3, nStarters: 6, nBattles: 4)
predictor = NaivePredictor.new(env)
pp predictor.predict(PRNG.new(0))

