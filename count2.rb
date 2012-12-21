# coding: utf-8
require "set"
require "pp"
require_relative "prng.rb"

NUM_ENTRIES = 30
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 7

# TODO 実際にありえるパスかどうかを判定する必要がある
def main
  starters = (0...NUM_STARTERS).to_a
  prng = PRNG.new(rand(2**32))
  p prng
  x = Counter.count(prng, starters)
  print_condition(x.to_a[0], starters)
end

# そのパスを通るために必要な条件を出力する
def print_condition(result, starters)
  p starters
  pp result
  maybe_players = []
  before = starters
  result.enemies.zip(result.skipped).each_with_index do |(enemy, skipped), i|
    enemy.each do |entry|
      if maybe_players.include?(entry)
        puts "#{entry} ∉ player[#{i-1}]"
      end
    end
    skipped.each do |entry|
      puts "#{entry} ∈ player[#{i-1}]"
    end
    maybe_players += before
    before = enemy
  end
end

class Counter
  def initialize(starters)
    @starters = starters
  end

  def self.count(prng, starters)
    new(starters).count(prng)
  end

  def count(prng)
    count0(prng, [], [])
  end

  Result = Struct.new(:prng, :enemies, :skipped)

  def count0(prng, enemies, skipped)
    if enemies.length == NUM_BATTLES
      return Set.new([Result.new(prng, enemies, skipped)])
    end
    prev_enemy = enemies.last || @starters
    maybe_players = @starters + enemies[0..-2].flatten
    surely_players = []
    results = OneEnemyCounter.count(prng, prev_enemy, maybe_players, surely_players)
    results.map {|result|
      count0(result.prng, enemies + [result.chosen], skipped + [result.skipped])
    }.inject(:+)
  end
end

class OneEnemyCounter
  def initialize(prev_enemy, maybe_players, surely_players)
    @prev_enemy = prev_enemy
    @maybe_players = maybe_players
    @surely_players = surely_players
  end

  def self.count(prng, prev_enemy, maybe_players, surely_players)
    new(prev_enemy, maybe_players, surely_players).count(prng)
  end

  def count(prng)
    count0(prng, @surely_players, [])
  end

  Result = Struct.new(:prng, :chosen, :skipped)

  # 戻り値の中の異なるResultオブジェクトは必ず異なるchosenになる
  def count0(prng, surely_players, chosen)
    if chosen.length == NUM_PARTY
       return Set.new([Result.new(prng, chosen, surely_players)])
    end
    prngp, x = prng.rand(NUM_ENTRIES)
    if (@prev_enemy + surely_players + chosen).include?(x)
      # 常にスキップ
      count0(prngp, surely_players, chosen)
    elsif not @maybe_players.include?(x) or surely_players.length == NUM_PARTY
      # 常に採用
      count0(prngp, surely_players, chosen + [x])
    else
      # プレイヤーがxを持っていてスキップする場合
      result1 = count0(prngp, surely_players + [x], chosen)
      # 採用する場合
      result2 = count0(prngp, surely_players, chosen + [x])

      result1 + result2
    end
  end
end

main() if $0 == __FILE__
