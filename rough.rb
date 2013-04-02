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
    if chosen.length == nParty
      return [chosen].to_set
    end
    # 3つのアイテムと種族を選んでskippedをカバーすることができないなら、
    # skippedの全エントリーがplayersと衝突するような3つのエントリーplayersは
    # 存在しないということなので、このルートはありえないとみなし空集合を返す
    if not coverable?(skipped)
      return [].to_set
    end
    prngp, x = choose_entry(prng)
    if x.collides_within?(chosen)
      # 既に採用済みの場合
      predict0(prngp, skipped, chosen)
    elsif skipped.include?(x)
      # まったく同じエントリをスキップしたことがある場合
      predict0(prngp, skipped, chosen)
    else
      result1 = predict0(prngp, skipped, chosen + [x])
      result2 = predict0(prngp, skipped + [x], chosen)
      result1 + result2
    end
  end

  # アイテムと種族をそれぞれ3つずつ適当に選べば、それらでentriesをカバーできるかを判定する
  # (注)
  #   "1つの敵のエントリーの決定範囲には同じ種族が複数存在しないこと"を前提にしている
  def coverable?(entries)
    coverd = Set.new
    selected_items = Set.new
    all_items = entries.map(&:item).to_set
    linked = Hash.new
    entries.each do |entry|
      (linked[entry.item] ||= Set.new).add entry
    end

    # カバーできるエントリーの個数についての貪欲法でアイテムを3つ選ぶ
    nParty.times do |i|
      items = all_items - selected_items
      break if items.empty?
      item = items.max_by {|item|
        (linked[item] - coverd).size
      }
      selected_items.add item
      coverd += linked[item]
    end
    # 残っているエントリーが3つ以下なら、それらの種族3つ選べばすべてカバーできることになる
    (entries.to_set - coverd).size <= 3
  end
end

class NaivePredictor
  def initialize(env)
    @env = env
  end

  attr_reader :env
  include EnvMixin 
  include FactoryHelper

  def predict(prng)
    result = Set.new
    all_entries().combination(3) do |players|
      result.add choose_entries(prng, nParty, players)
    end
    result
  end
end

env = Env.new(nParty: 3, nStarters: 6, nBattles: 4)
100.times do |i|
  seed = rand(2**32)
  prng = PRNG.new(seed)
  print "%.8x: " % seed
  result1 = Predictor.new(env).predict(prng)
  print "#{result1.size} results"
  result2 = NaivePredictor.new(env).predict(prng)
  print " / #{result2.size} results"
  print " / #{result2.subset?(result1)}"
  print "\n"
end

