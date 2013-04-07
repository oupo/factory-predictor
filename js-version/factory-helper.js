class Entry {
	constructor(id, item, pokemon) {
		this.id = id;
		this.item = item;
		this.pokemon = pokemon;
	}
	collides_with(other) {
		return this.item == other.item || this.pokemon == other.pokemon;
	}
	collides_within(entries) {
		return entries.some(x => this.collides_with(x))
	}
}

class Env {
	constructor(options) {
		this.nParty = options.nParty;
		this.nStarters = options.nStarters;
		this.nBattles = options.nBattles;
		this.allEntries = options.allEntries;
	}
}

class FactoryHelper {
	static choose_entry(env, prng) {
		let prngp = prng.dup();
		let x = this.choose_entryQ(env, prngp);
		return [prngp, x];
	}
	
	static choose_entryQ(env, prng) {
		let i = prng.randQ(env.allEntries.length);
		return env.allEntries[i];
	}
}


