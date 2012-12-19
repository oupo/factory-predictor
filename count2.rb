require "set"
require "pp"
require_relative "prng.rb"

def Array.product(x, n)
  Array.each_product(x, n).to_a
end

def Array.each_product(x, n)
  return to_enum(__method__, x, n) if not block_given?
  (x.size ** n).times do |elem|
    yield (n-1).downto(0).map{|i| x[(elem / (x.size ** i)) % x.size] }
  end
end

NUM_ENTRIES = 100
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 4
EXCHANGING = [nil] + Array.product((0..NUM_PARTY).to_a, 2)

def main
  starters = (0...NUM_STARTERS).to_a
  pp Naive.count(PRNG.new(0), starters)
end


# 素朴にすべての選出と交換を試す方法
module Naive
  module_function
  def count(prng, starters)
    set = Set.new
    starters.combination(NUM_PARTY).each do |player|
      each_exchanging do |exchanging|
        set.add choice_enemies(prng.dup, starters, player, exchanging)
      end
    end
    set
  end

  def each_exchanging
      Array.each_product(EXCHANGING, NUM_BATTLES - 2) do |exchanging|
        yield exchanging + [nil] # 最後の交換は影響しないから「なし」に固定していい
      end
  end

  def choice_enemies(prng, starters, player, exchanging)
    result = []
    before = starters
    NUM_BATTLES.times do |i|
      enemy = choice_enemy_party(prng, before)
      result.push enemy
      before = player + enemy
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

  def choice_enemy_party(prng, before)
    result = []
    while result.length < NUM_PARTY
      x = prng.rand(NUM_ENTRIES)
      if not (result + before).include?(x)
        result.push x
      end
    end
    result
  end
end

main() if $0 == __FILE__
