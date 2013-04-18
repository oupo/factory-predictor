import * from "./util.js";
import * from "./factory-helper.js";

export class RoughPredictor {
	constructor(env) {
		this.env = env;
	}

	static predict(env, prng) {
		return new this(env).predict(prng);
	}

	predict(prng) {
		let [prngp, starters] = FactoryHelper.choose_starters(this.env, prng);
		return this.predict0(prngp, [], [], starters);
	}

	predict0(prng, enemies, skipped, starters) {
		if (enemies.length == this.env.nBattles) {
			return [new RoughPredictorResult(prng, enemies, skipped, starters)];
		}
		let i = enemies.length;
		let unchoosable = enemies.last || starters;
		let maybe_players = [...starters, ...enemies.slice(0, i-1).flatten()];
		let results = OneEnemyPredictor.predict(this.env, prng, unchoosable, maybe_players);
		return results.map(result => {
			let prngp = FactoryHelper.after_consumption(env, result.prng, result.chosen, i);
			return this.predict0(prngp, [...enemies, result.chosen], [...skipped, result.skipped], starters);
		}).flatten();
	}
}


export class RoughPredictorResult {
	constructor(prng, enemies, skipped, starters) {
		this.prng = prng;
		this.enemies = enemies;
		this.skipped = skipped;
		this.starters = starters;
	}
}

export class OneEnemyPredictor {
	constructor(env, unchoosable, maybe_players) {
		this.env = env;
		this.unchoosable = unchoosable;
		this.maybe_players = maybe_players;
	}

	static predict(env, prng, unchoosable, maybe_players) {
		return new this(env, unchoosable, maybe_players).predict(prng);
	}

	predict(prng) {
		return this.predict0(prng, [], [])
	}
	
	predict0(prng, skipped, chosen) {
		if (chosen.length == this.env.nParty) {
			return [new OneEnemyPredictorResult(prng, chosen, skipped)];
		}
		let [prngp, x] = FactoryHelper.choose_entry(this.env, prng);
		if (x.collides_within([...this.unchoosable, ...chosen, ...skipped])) {
			return this.predict0(prngp, skipped, chosen);
		} else if (!x.collides_within(this.maybe_players) || skipped.length == this.env.nParty) {
			return this.predict0(prngp, skipped, [...chosen, x]);
		} else {
			let result1 = this.predict0(prngp, skipped, [...chosen, x]);
			let result2 = this.predict0(prngp, [...skipped, x], chosen);
			return [...result1, ...result2];
		}
	}
}

export class OneEnemyPredictorResult {
	constructor(prng, chosen, skipped) {
		this.prng = prng;
		this.chosen = chosen;
		this.skipped = skipped;
	}
}
