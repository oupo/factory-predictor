class RoughPredictor {
	constructor(env) {
		this.env = env;
	}

	static predict(env, prng) {
		return new this(env).predict(prng);
	}

	predict(prng) {
		let [prngp, starters] = FactoryHelper.choose_entries(this.env, prng, this.env.nStarters);
		return this.predict0(prngp, [], [], starters);
	}

	predict0(prng, enemies, skipped, starters) {
		if (enemies.length == this.env.nBattles) {
			return [new RoughPredictorResult(prng, enemies, skipped, starters)];
		}
		let unchoosable = enemies.last || starters;
		let maybe_players = [...starters, ...enemies.slice(0, -1).flatten()];
		let results = OneEnemyPredictor.predict(env, prng, unchoosable, maybe_players);
		return results.map(result =>
			this.predict0(result.prng, [...enemies, result.chosen], [...skipped, result.skipped], starters)
		).flatten();
	}
}


class RoughPredictorResult {
	constructor(prng, enemies, skipped, starters) {
		this.prng = prng;
		this.enemies = enemies;
		this.skipped = skipped;
		this.starters = starters;
	}
}

class OneEnemyPredictor {
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
			let result1 = this.predict0(prngp, skipped, [...chosen, x])
			let result2 = this.predict0(prngp, [...skipped, x], chosen)
			return [...result1, ...result2];
		}
	}
}

class OneEnemyPredictorResult {
	constructor(prng, chosen, skipped) {
		this.prng = prng;
		this.chosen = chosen;
		this.skipped = skipped;
	}
}