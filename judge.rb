# coding: utf-8
require "set"
require "pp"
require_relative "prng.rb"
require_relative "rough-predictor.rb"

NUM_ENTRIES = 30
NUM_STARTERS = 6
NUM_PARTY = 3
NUM_BATTLES = 7

N = NUM_BATTLES

# TODO 実際にありえるパスかどうかを判定する必要がある
def main
  starters = (0...NUM_STARTERS).to_a
  prng = PRNG.new(rand(2**32))
  p prng
  x = RoughPredictor.predict(prng, starters)
  print_condition(x.to_a[0], starters)
end

def print_condition(result, starters)
  shop, gate = result_to_shopgate(result, starters)
  (0..N - 2).each do |i|
    puts "shop #{i}: #{shop[i]}"
    puts "gate #{i+2}: #{gate[i+2]} : #{shop[i+2]}"
  end
end

def result_to_shopgate(result, starters)
  shop = []
  gate = []
  shop[0] = starters
  (1..N).each do |i|
    shop[i] = result.enemies[i-1]
  end
  (2..N).each do |i|
    gate[i] = result.skipped[i-1]
  end
  subst_item_id(shop, gate)
end

class Item
  def initialize(name)
    @name = name
  end

  def inspect
    @name
  end
end

def subst_item_id(shop, gate)
  ref = {}
  (0..N).each do |i|
    shop[i].each do |item|
      ref[item] ||= []
      ref[item] << i if i <= N - 2
    end
  end
  used = ref.values.each_with_object(Hash.new(0)) {|r, u| u[r] += 1 }
  count = Hash.new(0)
  name = {}
  ref.each do |item, r|
    n = r.join("")
    if used[r] > 1 or n == ""
      n += "_" + ("a".ord + count[r]).chr
    end
    name[item] = Item.new(n)
    count[r] += 1
  end
  shop.each {|x| x.map!{|item| name[item] } }
  gate.each {|x| x and x.map!{|item| name[item] } }
  [shop, gate]
end


main() if $0 == __FILE__
