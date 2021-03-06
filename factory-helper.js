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
	
	static choose_entry(env, prng, battle_index) {
		let prngp = prng.dup();
		let x = this.choose_entryQ(env, prngp, battle_index);
		return [prngp, x];
	}

	static choose_entryQ(env, prng, battle_index) {
		let [start, end] = this._choice_range(env, battle_index);
		let i = end - 1 - prng.randQ(end - start);
		return env.allEntries[i];
	}

	static _choice_range(env, battle_index) {
		if (battle_index != 7) {
			return [0, 150];
		} else {
			return [150, 250];
		}
	}
	
	static choose_entries(env, prng, n, battle_index, unchoosable=[]) {
		let prngp = prng.dup();
		let x = this.choose_entriesQ(env, prngp, n, battle_index, unchoosable);
		return [prngp, x];
	}
	
	static choose_entriesQ(env, prng, n, battle_index, unchoosable=[]) {
		let entries = [];
		while (entries.length < n) {
			let entry = this.choose_entryQ(env, prng, battle_index);
			if (!entry.collides_within([...entries, ...unchoosable])) {
				entries.push(entry);
			}
		}
		return entries;
	}

	static choose_starters(env, prng) {
		let prngp = prng.dup();
		let starters = this.choose_startersQ(env, prngp);
		return [prngp, starters];
	}

	static choose_startersQ(env, prng) {
		let starters = this.choose_entriesQ(env, prng, env.nStarters, 0);
		this._pid_loopQ(env, prng, starters);
		prng.stepQ(2);
		return starters;
	}

	static after_consumption(env, prng, entries, battle_index) {
		let prngp = prng.dup();
		this.after_consumptionQ(env, prngp, entries, battle_index);
		return prngp;
	}

	static after_consumptionQ(env, prng, entries, battle_index) {
		this._pid_loopQ(env, prng, entries);
		prng.stepQ(battle_index == 1 ? 24 : 6);
	}

	static _pid_loopQ(env, prng, entries) {
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


