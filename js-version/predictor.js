export * from "./env.js";
export * from "./prng.js";
export * from "./factory-helper.js";
import * from "./util.js";
import * from "./rough.js";
import * from "./judge.js";

export class Predictor {
	static predict(env, prng) {
		return RoughPredictor.predict(env, prng).filter(r => Judge.judge(env, r));
	}
}
