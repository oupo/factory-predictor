import * from "./predictor.js";
import * from "./rough.js";
import * from "./judge.js";
import * from "./util.js";

var fs = require("fs");

var csvString = fs.readFileSync("entries.csv", "utf8");
let allEntries = FactoryHelper.parseAllEntries(csvString);

let env = new Env({nParty: 3, nStarters: 6, nBattles: 7, allEntries: allEntries});
for (var i in Util.range(0, 10)) {
	let result = RoughPredictor.predict(env, new PRNG(i));
	let oks = result.map(r => Judge.judge(env, r)).count(x => x == true);
	console.log(`${oks} / ${result.length}`);
}
