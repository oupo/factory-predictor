# あらかじめスターターが決まっていて、そこからプレイヤーはパーティを選ぶ
# プレイヤーのパーティと被らないように1組エネミーのパーティを決める。
# このときすべてのプレイヤーの選び方に渡ったエネミーのパーティの全組み合わせを数える
# 
# エントリーの衝突の判定はIDだけによるなど単純化

require "set"
require_relative "prng.rb"

NUM_ENTRIES = 100
NUM_STARTERS = 6
NUM_PARTY = 3

def main
  starters = (0...NUM_STARTERS).to_a
  p Naive.count(PRNG.new(0), starters)
  p Fast.count(PRNG.new(0), starters)
end

# 枝分かれが起こる要素があったときに初めてそこで枝分かれする方法
module Fast
  module_function
  def count(prng, starters)
    count0(prng, starters, [], [])
  end

  def count0(prng, starters, player_determined, chosen)
    if chosen.length == NUM_PARTY
       return Set.new([chosen])
    end
    prngp, x = prng.rand(NUM_ENTRIES)
    if (player_determined + chosen).include?(x)
      # 常にスキップ
      count0(prngp, starters, player_determined, chosen)
    elsif not starters.include?(x) or player_determined.length == NUM_PARTY
      # 常に採用
      count0(prngp, starters, player_determined, chosen + [x])
    else
      # プレイヤーがxを持っていてスキップする場合
      result1 = count0(prngp, starters, player_determined + [x], chosen)
      # 採用する場合
      result2 = count0(prngp, starters, player_determined, chosen + [x])

      result1 + result2
    end
  end
end

# 素朴にすべての選出を試す方法
module Naive
  module_function
  def count(prng, starters)
    set = Set.new
    starters.combination(NUM_PARTY).each do |player|
      p = prng.dup
      enemy = choice_enemy_party(player, p)
      set.add enemy
    end
    set
  end

  def choice_enemy_party(player, p)
    result = []
    while result.length < NUM_PARTY
      x = p.rand!(NUM_ENTRIES)
      if not result.include?(x) and not player.include?(x)
        result.push x
      end
    end
    result
  end
end

main() if $0 == __FILE__
