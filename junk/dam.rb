require "set"
require "pp"

Dam = Struct.new(:id, :linked)

def main
  num_dams_a = 5
  num_dams_b = 5
  num_plants = 11
  srand 0
  r = {true => 0, false => 0}
  1000.times do |i|
    env = gen(num_dams_a, num_dams_b, num_plants)
    ret1, ret2 = naive_solve(*env), greedy_solve(*env)
    if (!!ret1) != (!!ret2)
      p [ret1, ret2]
      pp env
      exit
    end
    r[!!ret1] += 1
  end
  p r
end

def gen(num_dams_a, num_dams_b, num_plants)
  dams_a = num_dams_a.times.map {|i| Dam.new(i, []) }
  dams_b = num_dams_b.times.map {|i| Dam.new(num_dams_a + i, []) }
  plants = (0...num_plants).to_a
  plants.each do |plant|
    a = dams_a.sample
    b = dams_b.sample
    a.linked.push plant
    b.linked.push plant
  end
  [dams_a, dams_b, plants]
end

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

def naive_solve(dams_a, dams_b, plants)
  dams_a.combination(3) do |a|
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
