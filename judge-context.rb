class JudgeContext
  def initialize(shop, gate)
    @shop = shop
    @gate = gate
    @requests = list_requests(shop, gate)
  end

  attr_reader :shop, :gate, :requests

  def self.from_predictor_result(result, starters)
    shop = []
    gate = []
    shop[0] = starters.dup
    (1..N).each do |i|
      shop[i] = result.enemies[i-1].dup
    end
    (2..N).each do |i|
      gate[i] = result.skipped[i-1].dup
    end
    subst_item_id! shop, gate
    new(shop, gate)
  end

  # 要求されるworkのリスト
  def list_requests(shop, gate)
    req = []
    (2..N).each do |i|
      gate[i].each do |item|
        r = []
        (0..i-2).each do |j|
          if shop[j].include?(item)
            r << Work.new(item, j + 2, i)
          end
        end
        req << r
      end
    end
    req
  end

  class Item
    def initialize(name)
      @name = name
    end

    def inspect
      @name
    end
  end

  # デバッグのために、どこのshopで手に入れることができるかを表した名前にする
  def self.subst_item_id!(shop, gate)
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
end
