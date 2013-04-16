def main()
	g = {}
	add_edge g, :s, :u, 10
	add_edge_with_min g, :u, :v, 3, 5
	add_edge g, :v, :t, 10
	p max_flow(g, :S, :T)
	add_edge g, :S, :s, INF
	add_edge g, :t, :T, INF
	p max_flow(g, :S, :T)
end

def graph_solve(dams_a, dams_b, plants)
	g = {}
	add_edge g, :s, :A, 3
	add_edge g, :s, :B, 3
	dams_a.each do |dam|
		add_edge g, :A, :"dam_#{dam.id}", 1
	end
	dams_b.each do |dam|
		add_edge g, :B, :"dam_#{dam.id}", 1
	end

	dams = dams_a + dams_b
	dams.each do |dam|
		dam.linked.each do |plant|
			add_edge g, :"dam_#{dam.id}", :"plant_#{plant}", 1
		end
	end
	
	plants.each do |plant|
		add_edge_with_min g, :"plant_#{plant}", :"plant_out_#{plant}", 1, INF
	end
	
	plants.each do |plant|
		add_edge g, :"plant_out_#{plant}", :t, INF
	end
	
	m = plants.size
	if max_flow(g, :S, :T) >= m
		add_edge g, :S, :s, INF
		add_edge g, :t, :T, INF
		max_flow(g, :S, :T) - m
	else
		:impossible
	end
end

def add_edge_with_min(g, from, to, min, max)
	add_edge g, from, to, max - min
	add_edge g, :S, to, min
	add_edge g, from, :T, min
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
	flows = Hash.new(0)
	while true
		used = Hash.new(false)
		f = dfs(g, used, flows, s, t, INF)
		return flow if f == 0
		flow += f
	end
end

def dfs(g, used, flows, v, t, f)
	return f if v == t
	used[v] = true
	g[v].each do |e|
		if not used[e.to] and e.cap - flows[e] > 0
			d = dfs(g, used, flows, e.to, t, [f, e.cap - flows[e]].min)
			if d > 0
				flows[e] += d
				flows[g[e.to][e.rev]] -= d
				return d
			end
		end
	end
	0
end

main() if $0 == __FILE__
