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
  end

  attr_reader :nParty, :nStarters, :nBattles
end

module EnvMixin
  def nParty() env.nParty end
  def nStarters() env.nStarters end
  def nBattles() env.nBattles end
end

module FactoryHelper
  module_function
  def _load
    open("entries.csv", "rb").lines.map.with_index {|line, i|
      (item, pokemon) = line.split(",").map{|x| Integer(x) }
      Entry.new(i + 1, item, pokemon)
    }
  end

  ALL_ENTRIES = _load()

  def all_entries
    ALL_ENTRIES
  end

  def collision(a, b)
    a.item == b.item or a.pokemon == b.pokemon
  end

  def choose_entry(prng)
    prngp = prng.dup
    x = choose_entry!(prngp)
    [prngp, x]
  end

  def choose_entry!(prng)
    i = prng.rand!(all_entries.size)
    all_entries[i]
  end

  def choose_entries(prng, n, unchoosable=[])
    prngp = prng.dup
    entries = choose_entries!(prng, n, unchoosable)
    [prngp, entries]
  end

  def choose_entries!(prng, n, unchoosable=[])
    entries = []
    while entries.size < n
      entry = choose_entry!(prng)
      if not entry.collides_within?(entries + unchoosable)
        entries.push entry
      end
    end
    entries
  end
end

