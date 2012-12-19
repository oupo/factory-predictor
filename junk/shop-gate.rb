require "pp"

class ShopGateProbremSolver
  def initialize(first_items, shops, requirements, bad)
    @first_items = first_items
    @shops = shops
    @gate = requirements.zip(bad)
    @where_to_get = make_where_to_get()
  end

  def solve
    state = State.new(@first_items.size, @gate.size)
    each_gate do |req, bad, s|
      req.each do |item|
        positions = where(item, s)
        if positions.size == 1
          state.add(positions[0], s, item)
        end
      end
    end
    state.display
  end

  def where(item, scene)
    @where_to_get[item].take_while {|s| s <= scene }
  end

  def each_gate
    @gate.each_with_index do |(req, bad), i|
      yield req, bad, i + 1
    end
  end

  class State
    def initialize(num_lines, num_gate)
      @num_lines = num_lines
      @num_scene = num_gate + 1
      @state = @num_scene.times.map {|s|
        [nil] * @num_lines
      }
    end

    def display
      @num_scene.times do |s|
        print "%2d: " % s
        puts @state[s].map{|item| "%2s" % (item || "-") }.join(" ")
      end
    end

    def add(head, tail, item)
      line = find_line(head, tail)
      if already_exchanged?(head) or not line
        display(); $stdout.flush
        raise "impossible"
      else
        (head..tail).each do |s|
          @state[s][line] = item
        end
      end
    end

    def already_exchanged?(s)
      1 <= s and @num_lines.times.any?{|line|
        prev = @state[s-1][line]
        curr = @state[s][line]
        prev and curr and prev != curr
      }
    end

    def find_line(head, tail)
      (0...@num_lines).find {|line|
        (head..tail).all?{|t| @state[t][line] == nil }
      }
    end
  end

  def make_where_to_get
    where_to_get = Hash.new
    add = ->(item, i) { (where_to_get[item] ||= []) << i }
    @first_items.each {|item| add.(item, 0) }
    @shops.each_with_index do |items, i|
      items.each {|item| add.(item, i + 1) }
    end
    where_to_get.default = []
    where_to_get
  end
end

first = %w(a1 a2 a3)
shops = 10.times.map {|i|
  x = ("b".ord + i).chr
  3.times.map{|j|
    "#{x}#{j+1}"
  }
}
requirements = Array.new(10, [])
requirements[8-1] = ["d1"]
requirements[6-1] = ["e1"]
requirements[10-1] = ["a1", "h1"]
requirements[9-1] = ["j1"]

bad = Array.new(10, [])

solver = ShopGateProbremSolver.new(first, shops, requirements, bad)
solver.solve
