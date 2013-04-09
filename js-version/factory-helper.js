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
	static parseAllEntries(csvString) {
		return Util.split(csvString, "\n").map((line, i) => {
			let [pokemon, item] = line.split(",");
			return new Entry(i + 1, item, pokemon);
		});
	}
	
	static buildEnv(options) {
		var url = options.allEntriesURL;
		var data;
		await data = Util.xhr(url);
		var allEntries = this.parseAllEntries(data);
		return new Env({
			nParty: options.nParty,
			nStarters: options.nStarters,
			nBattles: options.nBattles,
			allEntries: allEntries
		});
	}
	
	static choose_entry(env, prng) {
		let prngp = prng.dup();
		let x = this.choose_entryQ(env, prngp);
		return [prngp, x];
	}
	
	static choose_entryQ(env, prng) {
		let i = prng.randQ(env.allEntries.length);
		return env.allEntries[i];
	}
	
	static choose_entries(env, prng, n, unchoosable=[]) {
		let prngp = prng.dup();
		let x = this.choose_entriesQ(env, prngp, n, unchoosable);
		return [prngp, x];
	}
	
	static choose_entriesQ(env, prng, n, unchoosable=[]) {
		let entries = [];
		while (entries.length < n) {
			let entry = this.choose_entryQ(env, prng);
			if (!entry.collides_within([...entries, ...unchoosable])) {
				entries.push(entry);
			}
		}
		return entries;
	}
}


