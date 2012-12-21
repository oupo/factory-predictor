class RoughPredictor
  def initialize(starters)
    @starters = starters
  end

  def self.predict(prng, starters)
    new(starters).predict(prng)
  end

  def predict(prng)
    predict0(prng, [], [])
  end

  Result = Struct.new(:prng, :enemies, :skipped)

  def predict0(prng, enemies, skipped)
    if enemies.length == NUM_BATTLES
      return Set.new([Result.new(prng, enemies, skipped)])
    end
    prev_enemy = enemies.last || @starters
    maybe_players = @starters + enemies[0..-2].flatten
    surely_players = []
    results = OneEnemyPredictor.predict(prng, prev_enemy, maybe_players, surely_players)
    results.map {|result|
      predict0(result.prng, enemies + [result.chosen], skipped + [result.skipped])
    }.inject(:+)
  end
end

class OneEnemyPredictor
  def initialize(prev_enemy, maybe_players, surely_players)
    @prev_enemy = prev_enemy
    @maybe_players = maybe_players
    @surely_players = surely_players
  end

  def self.predict(prng, prev_enemy, maybe_players, surely_players)
    new(prev_enemy, maybe_players, surely_players).predict(prng)
  end

  def predict(prng)
    predict0(prng, @surely_players, [])
  end

  Result = Struct.new(:prng, :chosen, :skipped)

  # 戻り値の中の異なるResultオブジェクトは必ず異なるchosenになる
  def predict0(prng, surely_players, chosen)
    if chosen.length == NUM_PARTY
       return Set.new([Result.new(prng, chosen, surely_players)])
    end
    prngp, x = prng.rand(NUM_ENTRIES)
    if (@prev_enemy + surely_players + chosen).include?(x)
      # 常にスキップ
      predict0(prngp, surely_players, chosen)
    elsif not @maybe_players.include?(x) or surely_players.length == NUM_PARTY
      # 常に採用
      predict0(prngp, surely_players, chosen + [x])
    else
      # プレイヤーがxを持っていてスキップする場合
      result1 = predict0(prngp, surely_players + [x], chosen)
      # 採用する場合
      result2 = predict0(prngp, surely_players, chosen + [x])

      result1 + result2
    end
  end
end
