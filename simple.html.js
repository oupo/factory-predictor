import * from "./predictor.js";
import * from "./util.js";
if (!('console' in window)) window.console = {log: x => x}

function icon_url(id) { return `http://veekun.com/dex/media/pokemon/icons/${id}.png`; }

var env;
var POKEMON_NAME_TO_ID;
function main() {
	await env = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 7,
		allEntriesURL: "entries.csv?1366277583"
	});
	await POKEMON_NAME_TO_ID = load_pokemon_name_to_id();
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

function exec(seed) {
	var result = Predictor.predict(env, new PRNG(seed));
	console.log(result);
	document.querySelector("#result").innerHTML = `
		結果: ${result.length} 件
		<table>
		<tr><td></td>${Util.iota(env.nBattles).map(i => `<td>${i+1}戦目</td>`).join("")}</tr>
		${
			result.map((r, i) =>
				`<tr>
				<td>${i}件目</td>
				${
					r.enemies.map(td).join("")
				}
				</tr>`
			).join("")
		}</table>
	`;

	function td(enemy) {
		return `<td>${enemy.map(x => {
			var id = POKEMON_NAME_TO_ID[x.pokemon];
			return `<img src="${icon_url(id)}" alt="${x.pokemon}">`;
		}).join("")}</td>`;
	}
}

window.addEventListener("load", () => {
	main().then(() => console.log("done"), e => console.log(e));
});
