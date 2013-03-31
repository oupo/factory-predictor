require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

# とりあえず1戦だけを考える。maybe_playersはなし
class Predictor
  def initialize(env)
    @env = env
  end

  attr_reader :env
  include EnvMixin 
  include FactoryHelper

  def predict(prng)
    predict0(prng, [], [])
  end

  def predict0(prng, skipped, chosen)
    while true
      if chosen.length == nParty
        return Set.new([chosen])
      end
      prngp, x = choose_entry(prng)
      if x.collides_within?(chosen)
        # 既に採用済みの場合
        prng = prngp
        next
      elsif skipped =~ all_entries() - similar_entries(chosen)
        # chosenと衝突しないエントリーを全てskipし尽くしてしまった場合
        return Set.new()
      elsif skipped.include?(x)
        # まったく同じエントリをスキップしたことがある場合
        prng = prngp
        next
      else
        result1 = predict0(prngp, skipped, chosen + [x])
        result2 = predict0(prngp, skipped + [x], chosen)
        return result1 + result2
      end
    end
  end

  def similar_entries(entries)
    all_entries().find_all {|entry|
      entry.collides_within?(entries)
    }
  end
end

class Array
  def =~(other)
    Set.new(self) == Set.new(other)
  end
end

env = Env.new(nParty: 3, nStarters: 6, nBattles: 4)
predictor = Predictor.new(env)
pp predictor.predict(PRNG.new(0))

