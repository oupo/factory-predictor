import * from "./predictor.js";
import * from "./util.js";
if (!('console' in window)) window.console = {log: x => x}

var gEnv;
var POKEMON_NAME_TO_ID;
var gPokemonImage;

function main() {
	await gEnv = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 7,
		allEntriesURL: "entries.csv?1366277583"
	});
	await POKEMON_NAME_TO_ID = load_pokemon_name_to_id();
	await gPokemonImage = loadImage("icons.png");

	document.body.innerHTML = `
		<h1>factory-predictor Demo</h1>
		<form action="" onsubmit="return false">
		seed: <input type="text" id="seed" value="0">
		<input type="submit" value="実行">
		</form>
		<div id="result"></div>
	`;
	document.querySelector("form").addEventListener("submit", () => {
		exec(Number(document.querySelector("#seed").value));
	}, false);
}

function load_pokemon_name_to_id() {
	var pokemon_names_str;
	await pokemon_names_str = Util.xhr("pokemon-names.txt");
	var pokemon_names = Util.split(pokemon_names_str, "\n");
	var name_to_id = Object.create(null);
	pokemon_names.forEach((name, i) => {
		name_to_id[name] = i + 1;
	});
	return name_to_id;
}

function loadImage(url) {
	var deferred = new Deferred;
	var image = new Image;
	image.src = url;
	image.onload = function() {
		deferred.callback(image);
	};
	image.onerror = function() {
		deferred.errback();
	};
	return deferred.createPromise();
}

function exec(seed) {
	var result = Predictor.predict(gEnv, new PRNG(seed));
	var tree = toTree(gEnv, result);
	var dumped = displayTree(gEnv, tree, 0);
	var pre = document.createElement("pre");
	pre.textContent = dumped;
	document.querySelector("#result").innerHTML = "";
	document.querySelector("#result").appendChild(pre);
}

function displayTree(env, tree, nest) {
	var indent = Util.str_repeat("--", nest + 1);
	var prefix = `${indent} ${nest+1}. `;
	var out = "";
	for (var [x, children] of tree) {
		out += `${prefix}${x.map(e => e.pokemon).join(" ")}\n`;
		out += displayTree(env, children, nest + 1);
	}
	return out;
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

window.addEventListener("load", () => {
	main().then(() => console.log("done"), e => console.log(e));
});
