import * from "./util.js";
import * from "./env.js";

export class FactoryHelper {
	static parseAllEntries(csvString) {
		const NATURE_NAMES = "がんばりや さみしがり ゆうかん いじっぱり やんちゃ ずぶとい すなお のんき わんぱく のうてんき おくびょう せっかち まじめ ようき むじゃき ひかえめ おっとり れいせい てれや うっかりや おだやか おとなしい なまいき しんちょう きまぐれ".split(" ");
		return Util.split(csvString, "\n").map((line, i) => {
			let [pokemon, item, natureName] = line.split(",");
			let nature = NATURE_NAMES.indexOf(natureName);
			return new Entry(i + 1, item, pokemon, nature);
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

	static _pid_loop(env, prng, entries) {
		for (let entry of entries) {
			let trainer_id = this._rand32Q(prng);
			while (true) {
				let pid = this._rand32Q(prng);
				if (pid % 25 == entry.nature) break;
			}
		}
	}

	static _rand32Q(prng) {
		let low = prng.randQ(0x10000);
		let high = prng.randQ(0x10000);
		return (high << 16 | low) >>> 0;
	}
}


