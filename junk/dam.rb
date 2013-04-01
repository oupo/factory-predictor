# ダムがいくつかあり、グループAとグループBに分かれている。
# 水道局がいくつかあり、各水道局はグループA, グループBそれぞれ1つずつのダムとつながっている。
# グループA, Bそれぞれから3つずつダムを選んで、そこからすべての水道局をたどれるようにしたい。
# それは可能か判定せよ。

require "set"
require "pp"

Dam = Struct.new(:id, :linked)

def main
  num_dams_a = 100
  num_dams_b = 5
  num_plants = 20
  srand 0
  r = {true => 0, false => 0}
  100.times do |i|
    env = gen(num_dams_a, num_dams_b, num_plants)
    ret1, ret2, ret3 = naive_solve(*env), greedy_solve(*env), greedy_solve2(*env)
    if [!!ret1, !!ret2, !!ret3].uniq.size != 1
      p [ret1, ret2, ret3]
      pp env
      exit
    end
    r[!!ret1] += 1
  end
  p r
end

def gen(num_dams_a, num_dams_b, num_plants)
  # グループAの各ダムとつながっている水道局はそれぞれ高々1つとして生成する
  dams_a = num_dams_a.times.map {|i| Dam.new(i, []) }
  dams_b = num_dams_b.times.map {|i| Dam.new(num_dams_a + i, []) }
  plants = (0...num_plants).to_a
  dams_a_unchosen = dams_a.dup
  plants.each do |plant|
    a = dams_a_unchosen.sample
    b = dams_b.sample
    dams_a_unchosen.delete(a)
    a.linked.push plant
    b.linked.push plant
  end
  [dams_a, dams_b, plants]
end

# カバーできる水道局の個数についての貪欲法
def greedy_solve(dams_a, dams_b, plants)
  coverd = Set.new
  selected_dams = Set.new

  6.times do |i|
    dams = Set.new
    dams += dams_a if (selected_dams & dams_a).size < 3
    dams += dams_b if (selected_dams & dams_b).size < 3
    dams -= selected_dams
    break if dams.empty?
    dam = dams.max_by {|dam|
      (dam.linked.to_set - coverd).size
    }
    selected_dams.add dam
    coverd += dam.linked
  end
  coverd == plants.to_set ? selected_dams : nil
end

# (グループAの各ダムとつながっている水道局はそれぞれ高々1つだという前提のもとに)
# グループBから3つ、カバーできる水道局の個数について貪欲にダムを選ぶ
# その後残っている水道局が3つ以下かどうかで判定
def greedy_solve2(dams_a, dams_b, plants)
  coverd = Set.new
  selected_dams = Set.new

  3.times do |i|
    dams = dams_b.to_set - selected_dams
    break if dams.empty?
    dam = dams.max_by {|dam|
      (dam.linked.to_set - coverd).size
    }
    selected_dams.add dam
    coverd += dam.linked
  end
  (plants.to_set - coverd).size <= 3
end

# 全てのダムの選び方をしらみつぶし
def naive_solve(dams_a, dams_b, plants)
  dams_a.select{|x| not x.linked.empty? }.combination(3) do |a|
    dams_b.combination(3) do |b|
      coverd = Set.new
      (a + b).each do |dam|
        dam.linked.each do |plant|
          coverd.add plant
        end
      end
      return (a + b).to_set if coverd == plants.to_set
    end
  end
  nil
end

main() if $0 == __FILE__
