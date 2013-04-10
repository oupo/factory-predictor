export class Entry {
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

export class Env {
	constructor(options) {
		this.nParty = options.nParty;
		this.nStarters = options.nStarters;
		this.nBattles = options.nBattles;
		this.allEntries = options.allEntries;
	}
}

