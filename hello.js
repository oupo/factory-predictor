import * from "./predictor.js";
import * from "./rough.js";
import * from "./judge.js";
import * from "./util.js";

main();

function main() {
	var fs = require("fs");
	var csvString = fs.readFileSync("entries.csv", "utf8");
	let allEntries = FactoryHelper.parseAllEntries(csvString);
	let env = new Env({nParty: 3, nStarters: 6, nBattles: 7, allEntries: allEntries});
	
	let result = Predictor.predict(env, new PRNG(0));
	let tree = toTree(env, result);
	displayTree(env, tree, 0);
}

function displayTree(env, tree, nest) {
	var indent = Util.str_repeat("--", nest + 1);
	var prefix = `${indent} ${nest+1}. `;
	for (var [x, children] of tree) {
		console.log(`${prefix}${x.map(e => e.pokemon).join(" ")}`);
		displayTree(env, children, nest + 1);
	}
}

function toTree(env, results) {
	return toTree0(env, results, 0);
}

function toTree0(env, results, i) {
	function toKey(r) {
		return r.enemies[i];
	}
	
	if (i == env.nBattles - 1) {
		return results.map(x => [toKey(x), []]);
	} else {
		return groupBy(results, toKey).map(([key, elems]) => [key, toTree0(env, elems, i + 1)]);
	}
}

function groupBy(array, toKey) {
	var result = [];
	for (var x of array) {
		var key = toKey(x);
		var found = result.find(([k, elems]) => equals(k, key));
		
		if (!found) {
			result.push([key, [x]]);
		} else {
			var [k, elems] = found;
			elems.push(x);
		}
	}
	return result;
}

function equals(a, b) {
	if (Array.isArray(a) && Array.isArray(b)) {
		return a.length === b.length && a.every((x, i) => equals(a[i], b[i]));
	} else {
		return a === b;
	}
}
