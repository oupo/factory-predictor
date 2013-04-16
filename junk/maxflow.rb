def main
	g = {}
	add_edge g, :s, :a, 100
	add_edge g, :s, :b, 2
	add_edge g, :a, :b, 6
	add_edge g, :a, :c, 6
	add_edge g, :b, :t, 5
	add_edge g, :c, :b, 3
	add_edge g, :c, :t, 8
	p max_flow(g, :s, :t)
end

Edge = Struct.new(:to, :cap, :rev)

def add_edge(g, from, to, cap)
	g[from] ||= []
	g[to] ||= []
	i, j = g[from].size, g[to].size
	g[from][i] = Edge.new(to, cap, j)
	g[to][j] = Edge.new(from, 0, i)
end

INF = Float::INFINITY

def max_flow(g, s, t)
	flow = 0
	while true
		used = Hash.new(false)
		f = dfs(g, used, s, t, INF)
		return flow if f == 0
		flow += f
	end
end

def dfs(g, used, v, t, f)
	return f if v == t
	used[v] = true
	g[v].each do |e|
		if not used[e.to] and e.cap > 0
			d = dfs(g, used, e.to, t, [f, e.cap].min)
			if d > 0
				e.cap -= d
				g[e.to][e.rev].cap += d
				return d
			end
		end
	end
	0
end

main() if $0 == __FILE__
