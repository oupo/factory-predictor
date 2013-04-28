require "set"
require "pp"
require_relative "prng.rb"
require_relative "factory-helper.rb"

# 1つの敵のエントリーの決定範囲には同じ種族が複数存在しないという前提を外した試作バージョン

class Predictor
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
    prngp, x = choose_entry(prng)
    if x.collides_within?(chosen)
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
    nParty.times do |i|
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
result1 = Predictor.new(env).predict(PRNG.new(0))
puts "#{result1.size} results."
result2 = NaivePredictor.new(env).predict(PRNG.new(0))
puts "#{result2.size} results."
p result2.subset?(result1)
