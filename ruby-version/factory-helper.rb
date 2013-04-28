Entry = Struct.new(:id, :item, :pokemon)

Entry.class_eval do
  def collides_with?(other)
    self.item == other.item or self.pokemon == other.pokemon
  end

  def collides_within?(entries)
    entries.any?{|x| collides_with?(x) }
  end

  def inspect
    "entry#%03d" % self.id
  end

  def pretty_print(q)
    q.text inspect()
  end
end

class Env
  def initialize(hash)
    @nParty = hash[:nParty]
    @nStarters = hash[:nStarters]
    @nBattles = hash[:nBattles]
    @all_entries = (hash[:all_entries] \
                     or FactoryHelper.load_entries_database(hash[:all_entries_file]))
  end

  attr_reader :nParty, :nStarters, :nBattles, :all_entries
end

module EnvMixin
  def nParty() env.nParty end
  def nStarters() env.nStarters end
  def nBattles() env.nBattles end
end

module FactoryHelper
  module_function
  def load_entries_database(filename)
    open(filename, "rb").lines.map.with_index {|line, i|
      (item, pokemon) = line.split(",").map{|x| Integer(x) }
      Entry.new(i + 1, item, pokemon)
    }
  end

  def gen_all_entries(n_entries, n_items, n_pokemons)
    random = Random.new(0) # 再現性のため種を固定
    (0...n_entries).map {|i|
      item = :"item_#{random.rand(n_items)}"
      pokemon = :"pokemon_#{random.rand(n_pokemons)}"
      Entry.new(i, item, pokemon)
    }
  end

  def collision(a, b)
    a.item == b.item or a.pokemon == b.pokemon
  end

  def choose_entry(env, prng)
    prngp = prng.dup
    x = choose_entry!(env, prngp)
    [prngp, x]
  end

  def choose_entry!(env, prng)
    i = prng.rand!(env.all_entries.size)
    env.all_entries[i]
  end

  def choose_entries(env, prng, n, unchoosable=[])
    prngp = prng.dup
    entries, skipped = choose_entries!(env, prngp, n, unchoosable)
    [prngp, entries, skipped]
  end

  def choose_entries!(env, prng, n, unchoosable=[])
    entries = []
    skipped = []
    while entries.size < n
      entry = choose_entry!(env, prng)
      if entry.collides_within?(entries + unchoosable)
        skipped.push entry
      else
        entries.push entry
      end
    end
    [entries, skipped]
  end
end

