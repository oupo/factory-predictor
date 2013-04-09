var env;

function main() {
	await env = FactoryHelper.buildEnv({
		nParty: 3,
		nStarters: 6,
		nBattles: 7,
		allEntriesURL: "entries.csv"
	});
	document.body.innerHTML = `
		<h1>factory-predictor</h1>
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
					r.enemies.map(enemy =>
						`<td>${enemy.map(x => x.pokemon).join(",")}</td>`).join("")
				}
				</tr>`
			).join("")
		}</table>
	`;
}
window.addEventListener("load", () => {
	main().then(() => console.log("done"), e => console.log(e));
});
