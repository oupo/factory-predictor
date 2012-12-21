# coding: utf-8
require "set"
require "pp"
require_relative "prng.rb"
require_relative "rough-predictor.rb"

NUM_ENTRIES = 30
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 7

# TODO 実際にありえるパスかどうかを判定する必要がある
def main
  starters = (0...NUM_STARTERS).to_a
  prng = PRNG.new(rand(2**32))
  p prng
  x = RoughPredictor.predict(prng, starters)
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


main() if $0 == __FILE__
